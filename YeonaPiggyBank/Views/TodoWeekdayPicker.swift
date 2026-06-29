import SwiftUI

struct TodoWeekdayPicker: View {
    @Binding var selected: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Button {
                    selected = TodoWeekdayHelper.allWeekdays
                } label: {
                    Text("월~금")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selected == TodoWeekdayHelper.allWeekdays
                                      ? Color(hex: "6B8EAE")
                                      : Color(hex: "6B8EAE").opacity(0.12))
                        )
                        .foregroundStyle(selected == TodoWeekdayHelper.allWeekdays ? .white : Color(hex: "6B8EAE"))
                }
                .buttonStyle(.plain)

                ForEach(TodoWeekdayHelper.weekdayOptions, id: \.value) { option in
                    Button {
                        toggle(option.value)
                    } label: {
                        Text(option.label)
                            .font(.caption.bold())
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(selected.contains(option.value)
                                          ? Color(hex: "8B6914")
                                          : Color(.systemGray5))
                            )
                            .foregroundStyle(selected.contains(option.value) ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("선택: \(TodoWeekdayHelper.labels(for: Array(selected).sorted()))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func toggle(_ day: Int) {
        if selected.contains(day) {
            selected.remove(day)
        } else {
            selected.insert(day)
        }
    }
}
