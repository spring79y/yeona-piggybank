import SwiftUI
import WidgetKit

struct TodoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodoWidgetEntry

    private var snapshot: TodoWidgetSnapshot { entry.snapshot }
    private var accent: Color { Color(red: 0.545, green: 0.412, blue: 0.078) }
    private var success: Color { Color(red: 0.26, green: 0.63, blue: 0.45) }

    var body: some View {
        switch family {
        case .systemExtraLarge:
            extraLargeView
        case .systemMedium:
            mediumView
        default:
            largeView
        }
    }

    private var widgetSubtitleColor: Color {
        Color(red: 0.45, green: 0.38, blue: 0.28)
    }

    private var widgetItemTextColor: Color {
        Color(red: 0.20, green: 0.16, blue: 0.12)
    }

    private var mediumHeaderRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘의 할 일")
                .font(.headline.bold())
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: 8) {
                Text(snapshot.scheduleLabel)
                    .font(.caption2)
                    .foregroundStyle(widgetSubtitleColor)

                Spacer(minLength: 4)

                if !snapshot.isEmpty {
                    Text("\(snapshot.completedCount)/\(snapshot.totalCount)")
                        .font(.subheadline.bold())
                        .foregroundStyle(snapshot.allComplete ? success : accent)
                        .monospacedDigit()
                }

                if snapshot.isLocked {
                    Text("마감")
                        .font(.caption.bold())
                        .foregroundStyle(widgetSubtitleColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.06)))
                } else if let countdown = snapshot.countdownText {
                    Text(countdown)
                        .font(.caption2.bold())
                        .foregroundStyle(accent)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘의 할 일")
                .font(family == .systemExtraLarge ? .title.bold() : .title2.bold())
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: 12) {
                Text(snapshot.scheduleLabel)
                    .font(family == .systemExtraLarge ? .subheadline : .caption)
                    .foregroundStyle(widgetSubtitleColor)

                Spacer(minLength: 4)

                if !snapshot.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(snapshot.completedCount)/\(snapshot.totalCount)")
                            .font(family == .systemExtraLarge ? .largeTitle.bold() : .title.bold())
                            .foregroundStyle(snapshot.allComplete ? success : accent)
                            .monospacedDigit()

                        ProgressView(
                            value: Double(snapshot.completedCount),
                            total: Double(max(snapshot.totalCount, 1))
                        )
                        .tint(snapshot.allComplete ? success : accent)
                        .frame(width: family == .systemExtraLarge ? 180 : 120)
                    }
                }

                if snapshot.isLocked {
                    Text("마감")
                        .font(.headline.bold())
                        .foregroundStyle(widgetSubtitleColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.06)))
                } else if let countdown = snapshot.countdownText {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("오늘 밤 9시까지")
                            .font(.caption.bold())
                            .foregroundStyle(widgetSubtitleColor)
                        Text(countdown)
                            .font(family == .systemExtraLarge ? .title3.bold() : .headline.bold())
                            .foregroundStyle(accent)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            mediumHeaderRow

            if snapshot.isEmpty {
                Spacer(minLength: 0)
                Text("할 일이 없어요")
                    .font(.caption)
                    .foregroundStyle(widgetSubtitleColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if snapshot.allComplete {
                Spacer(minLength: 0)
                Label("모두 해냈어요!", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(success)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(snapshot.items.prefix(4)) { item in
                        todoItemRow(item, font: .caption)
                    }
                    if snapshot.items.count > 4 {
                        Text("+\(snapshot.items.count - 4)개 더")
                            .font(.caption2)
                            .foregroundStyle(widgetSubtitleColor)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            if snapshot.isEmpty {
                Spacer(minLength: 0)
                Text("엄마가 할 일을 올리면 여기에 보여요")
                    .font(.body)
                    .foregroundStyle(widgetSubtitleColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if snapshot.allComplete {
                Spacer(minLength: 0)
                Label("모두 해냈어요!", systemImage: "checkmark.circle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(success)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(snapshot.items) { item in
                        todoItemRow(item, font: .body)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var extraLargeView: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow

            if snapshot.isEmpty {
                Spacer(minLength: 0)
                Text("엄마가 할 일을 올리면 여기에 보여요")
                    .font(.title3)
                    .foregroundStyle(widgetSubtitleColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if snapshot.allComplete {
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    Label("모두 해냈어요!", systemImage: "checkmark.circle.fill")
                        .font(.largeTitle.bold())
                        .foregroundStyle(success)
                    Text(ChildNameSettings.celebrationPraise)
                        .font(.title3)
                        .foregroundStyle(widgetSubtitleColor)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(snapshot.items) { item in
                        todoItemRow(item, font: .title3)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func todoItemRow(_ item: TodoItem, font: Font) -> some View {
        let pendingColor = Color(red: 1.0, green: 0.55, blue: 0.26)
        HStack(spacing: 10) {
            Image(systemName: item.completed ? "checkmark.circle.fill" : (item.isAwaitingMomApproval ? "clock.fill" : "circle"))
                .font(font.weight(.bold))
                .foregroundStyle(item.completed ? success : (item.isAwaitingMomApproval ? pendingColor : widgetSubtitleColor))
            Text(item.text)
                .font(font)
                .foregroundStyle(item.completed ? widgetSubtitleColor : widgetItemTextColor)
                .lineLimit(family == .systemMedium ? 1 : 2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
            if item.isAwaitingMomApproval {
                Text("대기")
                    .font(.caption2.bold())
                    .foregroundStyle(pendingColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, family == .systemMedium ? 8 : 12)
        .padding(.vertical, family == .systemMedium ? 6 : 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(item.completed ? 0.45 : 0.72))
        )
    }
}

#Preview(as: .systemMedium) {
    TodoWidget()
} timeline: {
    TodoWidgetEntry(
        date: Date(),
        snapshot: TodoWidgetSnapshot(
            scheduleLabel: "평일",
            items: [
                TodoItem(id: "1", text: "숙제하기", completed: true),
                TodoItem(id: "2", text: "책 읽기", completed: false),
                TodoItem(id: "3", text: "양치하기", completed: false),
            ],
            completedCount: 1,
            totalCount: 3,
            countdownText: "2시 15분 30초",
            isLocked: false,
            isEmpty: false,
            allComplete: false
        )
    )
}

#Preview(as: .systemLarge) {
    TodoWidget()
} timeline: {
    TodoWidgetEntry(
        date: Date(),
        snapshot: TodoWidgetSnapshot(
            scheduleLabel: "평일",
            items: [
                TodoItem(id: "1", text: "숙제하기", completed: true),
                TodoItem(id: "2", text: "책 읽기", completed: false),
                TodoItem(id: "3", text: "양치하기", completed: false),
            ],
            completedCount: 1,
            totalCount: 3,
            countdownText: "2시 15분 30초",
            isLocked: false,
            isEmpty: false,
            allComplete: false
        )
    )
}

#Preview(as: .systemExtraLarge) {
    TodoWidget()
} timeline: {
    TodoWidgetEntry(
        date: Date(),
        snapshot: TodoWidgetSnapshot(
            scheduleLabel: "주말",
            items: [
                TodoItem(id: "1", text: "방 정리", completed: true),
                TodoItem(id: "2", text: "피아노 연습", completed: true),
                TodoItem(id: "3", text: "일기 쓰기", completed: false),
                TodoItem(id: "4", text: "책 읽기", completed: false),
                TodoItem(id: "5", text: "운동하기", completed: false),
            ],
            completedCount: 2,
            totalCount: 5,
            countdownText: "5시 0분 0초",
            isLocked: false,
            isEmpty: false,
            allComplete: false
        )
    )
}
