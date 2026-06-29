import SwiftUI

struct MomTodoEditorView: View {
    @ObservedObject var todoStore: TodoStore
    @Environment(\.dismiss) private var dismiss

    @State private var scheduleKey: TodoScheduleKey = .weekday
    @State private var draftRowIDs: [UUID] = []
    @State private var draftTexts: [UUID: String] = [:]
    @State private var draftWeekdays: [UUID: Set<Int>] = [:]
    @State private var inlineMessage: String?
    @State private var inlineIsError = true

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("일정", selection: $scheduleKey) {
                    ForEach(TodoScheduleKey.allCases) { key in
                        Text(key.label).tag(key)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: scheduleKey) { _, _ in loadDraft() }

                Text(scheduleKey == .weekday
                     ? "평일 할 일마다 요일(월~금)을 고를 수 있어요."
                     : "할 일을 입력하고 게시하면 메인 화면에 포스트잇으로 보여요.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if let inlineMessage {
                Text(inlineMessage)
                    .font(.caption.bold())
                    .foregroundStyle(inlineIsError ? Color(hex: "E8456A") : Color(hex: "4ECDC4"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }

            ScrollView {
                draftFields
                    .padding(.top, 12)
            }
            .frame(maxHeight: 300)

            Button {
                publish()
            } label: {
                Text("게시하기")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "8B6914"))
                    )
            }
            .padding(.top, 12)
        }
        .onAppear { loadDraft() }
    }

    private func loadDraft() {
        inlineMessage = nil
        let items = todoStore.schedule(for: scheduleKey).items
        if items.isEmpty {
            let id = UUID()
            draftRowIDs = [id]
            draftTexts = [id: ""]
            draftWeekdays = [id: TodoWeekdayHelper.allWeekdays]
        } else {
            var ids: [UUID] = []
            var texts: [UUID: String] = [:]
            var weekdays: [UUID: Set<Int>] = [:]
            for item in items {
                let id = UUID()
                ids.append(id)
                texts[id] = item.text
                weekdays[id] = Set(item.effectiveWeekdays)
            }
            draftRowIDs = ids
            draftTexts = texts
            draftWeekdays = weekdays
        }
    }

    private func publish() {
        let entries: [(text: String, weekdays: Set<Int>)] = draftRowIDs.compactMap { id in
            let text = draftTexts[id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else { return nil }
            return (text, draftWeekdays[id] ?? TodoWeekdayHelper.allWeekdays)
        }

        guard !entries.isEmpty else {
            inlineIsError = true
            inlineMessage = "할 일을 하나 이상 입력해 주세요."
            return
        }
        guard entries.count <= TodoPostItLayout.layouts.count else {
            inlineIsError = true
            inlineMessage = "최대 \(TodoPostItLayout.layouts.count)개까지 등록할 수 있어요."
            return
        }
        if scheduleKey == .weekday, entries.contains(where: { $0.weekdays.isEmpty }) {
            inlineIsError = true
            inlineMessage = "각 할 일마다 요일을 하나 이상 선택해 주세요."
            return
        }

        todoStore.publish(
            items: entries.map { entry in
                (text: entry.text, weekdays: scheduleKey == .weekday ? entry.weekdays : nil)
            },
            schedule: scheduleKey
        )
        inlineIsError = false
        inlineMessage = "\(scheduleKey.label) 할 일을 게시했어요!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }

    @ViewBuilder
    private var draftFields: some View {
        VStack(spacing: 14) {
            ForEach(draftRowIDs, id: \.self) { rowID in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        StableTodoTextField(
                            text: textBinding(for: rowID),
                            placeholder: "할 일"
                        )
                        .frame(height: 36)

                        if draftRowIDs.count > 1 {
                            Button {
                                removeRow(rowID)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    if scheduleKey == .weekday {
                        TodoWeekdayPicker(selected: weekdaysBinding(for: rowID))
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.6))
                )
            }

            Button {
                addRow()
            } label: {
                Label("할 일 추가", systemImage: "plus.circle.fill")
                    .font(.subheadline.bold())
            }
            .disabled(draftRowIDs.count >= TodoPostItLayout.layouts.count)
        }
    }

    private func addRow() {
        let id = UUID()
        draftRowIDs.append(id)
        draftTexts[id] = ""
        draftWeekdays[id] = TodoWeekdayHelper.allWeekdays
    }

    private func removeRow(_ id: UUID) {
        draftRowIDs.removeAll { $0 == id }
        draftTexts.removeValue(forKey: id)
        draftWeekdays.removeValue(forKey: id)
    }

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { draftTexts[id] ?? "" },
            set: { draftTexts[id] = $0 }
        )
    }

    private func weekdaysBinding(for id: UUID) -> Binding<Set<Int>> {
        Binding(
            get: { draftWeekdays[id] ?? TodoWeekdayHelper.allWeekdays },
            set: { draftWeekdays[id] = $0 }
        )
    }
}
