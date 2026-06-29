import WidgetKit
import SwiftUI

struct TodoWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TodoWidgetSnapshot
}

struct TodoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoWidgetEntry {
        TodoWidgetEntry(
            date: Date(),
            snapshot: TodoWidgetSnapshot(
                scheduleLabel: "평일",
                items: [
                    TodoItem(id: "1", text: "숙제하기", completed: true),
                    TodoItem(id: "2", text: "책 읽기", completed: false),
                ],
                completedCount: 1,
                totalCount: 2,
                countdownText: "3시 20분 0초",
                isLocked: false,
                isEmpty: false,
                allComplete: false
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoWidgetEntry) -> Void) {
        let date = Date()
        completion(TodoWidgetEntry(date: date, snapshot: TodoWidgetSnapshot.load(from: date)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoWidgetEntry>) -> Void) {
        let now = Date()
        var entries: [TodoWidgetEntry] = []

        for minuteOffset in 0..<60 {
            guard let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) else { continue }
            entries.append(
                TodoWidgetEntry(
                    date: entryDate,
                    snapshot: TodoWidgetSnapshot.load(from: entryDate)
                )
            )
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct TodoWidget: Widget {
    let kind = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoWidgetProvider()) { entry in
            TodoWidgetView(entry: entry)
                .widgetURL(URL(string: "yeonapiggybank://todo"))
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.97, green: 0.95, blue: 0.90), Color(red: 0.93, green: 0.88, blue: 0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("오늘의 할 일")
        .description("To Do List 현황을 확인해요.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@main
struct YeonaPiggyBankWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodoWidget()
    }
}
