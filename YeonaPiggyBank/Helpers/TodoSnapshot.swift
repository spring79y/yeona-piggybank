import Foundation

struct TodoWidgetSnapshot: Equatable {
    let scheduleLabel: String
    let items: [TodoItem]
    let completedCount: Int
    let totalCount: Int
    let countdownText: String?
    let isLocked: Bool
    let isEmpty: Bool
    let allComplete: Bool

    static func load(from date: Date = Date()) -> TodoWidgetSnapshot {
        AppGroupStorage.migrateTodoDataIfNeeded()
        let scheduleKey = TodoCycleHelper.activeScheduleKey(from: date)
        let state = normalizedState(from: date)
        let schedule = scheduleKey == .weekday ? state.weekday : state.weekend
        let visible = schedule.items.filter { $0.isActive(on: date, scheduleKey: scheduleKey) }
        let completed = visible.filter(\.completed).count
        let total = visible.count
        let countdown = TodoCycleHelper.isActivePeriod(from: date)
            ? TodoCycleHelper.countdownText(from: date)
            : nil
        let hasPublished = schedule.published && !schedule.items.isEmpty

        return TodoWidgetSnapshot(
            scheduleLabel: scheduleKey.label,
            items: visible,
            completedCount: completed,
            totalCount: total,
            countdownText: countdown,
            isLocked: TodoCycleHelper.isLocked(from: date),
            isEmpty: !hasPublished || visible.isEmpty,
            allComplete: hasPublished && total > 0 && completed == total
        )
    }

    private static func normalizedState(from date: Date) -> TodoState {
        var state = AppGroupStorage.loadTodoState()

        let cycleKey = TodoCycleHelper.cycleDateKey(from: date)
        guard state.resetDateKey != cycleKey else { return state }

        for key in TodoScheduleKey.allCases {
            switch key {
            case .weekday:
                for index in state.weekday.items.indices {
                    state.weekday.items[index].completed = false
                    state.weekday.items[index].pendingApproval = false
                }
                state.weekday.rewardClaimed = false
            case .weekend:
                for index in state.weekend.items.indices {
                    state.weekend.items[index].completed = false
                    state.weekend.items[index].pendingApproval = false
                }
                state.weekend.rewardClaimed = false
            }
        }
        state.resetDateKey = cycleKey
        return state
    }
}
