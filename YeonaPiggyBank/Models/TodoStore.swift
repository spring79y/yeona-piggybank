import Foundation

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var state: TodoState
    @Published var showCelebration = false
    @Published var showRewardSheet = false
    @Published var pulseToken = 0
    @Published private(set) var lastRewardBankTypes: [PiggyBankType] = []

    init() {
        AppGroupStorage.migrateTodoDataIfNeeded()
        state = AppGroupStorage.loadTodoState()
        ensureCycleDay()
    }

    func schedule(for key: TodoScheduleKey) -> TodoSchedule {
        key == .weekday ? state.weekday : state.weekend
    }

    func activeScheduleKey(from date: Date = Date()) -> TodoScheduleKey {
        TodoCycleHelper.activeScheduleKey(from: date)
    }

    func activeSchedule(from date: Date = Date()) -> TodoSchedule {
        schedule(for: activeScheduleKey(from: date))
    }

    func visibleItems(from date: Date = Date()) -> [TodoItem] {
        let key = activeScheduleKey(from: date)
        let items = activeSchedule(from: date).items
        return items.filter { $0.isActive(on: date, scheduleKey: key) }
    }

    func pendingItems(from date: Date = Date()) -> [TodoItem] {
        visibleItems(from: date).filter(\.isAwaitingMomApproval)
    }

    func hasPendingApprovals(from date: Date = Date()) -> Bool {
        !pendingItems(from: date).isEmpty
    }

    func hasPublishedSchedule(from date: Date = Date()) -> Bool {
        activeSchedule(from: date).published && !activeSchedule(from: date).items.isEmpty
    }

    func ensureCycleDay() {
        let cycleKey = TodoCycleHelper.cycleDateKey()
        guard state.resetDateKey != cycleKey else { return }
        for key in TodoScheduleKey.allCases {
            resetCompletion(for: key)
        }
        state.resetDateKey = cycleKey
        save()
    }

    func resetAll() {
        state = TodoState(
            resetDateKey: TodoCycleHelper.cycleDateKey(),
            weekday: TodoSchedule(),
            weekend: TodoSchedule()
        )
        save()
    }

    func publish(items: [(text: String, weekdays: Set<Int>?)], schedule key: TodoScheduleKey) {
        ensureCycleDay()
        let newItems = items.enumerated().map { index, entry in
            let weekdayList: [Int]? = {
                guard key == .weekday, let days = entry.weekdays, !days.isEmpty else { return nil }
                return days.sorted()
            }()
            return TodoItem(
                id: "\(Date().timeIntervalSince1970)_\(index)_\(UUID().uuidString.prefix(4))",
                text: entry.text,
                completed: false,
                pendingApproval: false,
                weekdays: weekdayList
            )
        }
        switch key {
        case .weekday:
            state.weekday.items = newItems
            state.weekday.published = true
            state.weekday.rewardClaimed = false
        case .weekend:
            state.weekend.items = newItems
            state.weekend.published = true
            state.weekend.rewardClaimed = false
        }
        save()
    }

    /// 아이: 완료 대기로 보냄 (9시 전만 가능)
    @discardableResult
    func markPendingApproval(id: String, date: Date = Date()) -> Bool {
        guard TodoCycleHelper.isActivePeriod(from: date) else { return false }
        let key = activeScheduleKey(from: date)
        guard let item = visibleItems(from: date).first(where: { $0.id == id }),
              !item.completed, !item.pendingApproval else { return false }
        guard mutateItem(id: id, in: key, mutate: { $0.pendingApproval = true }) else { return false }
        save()
        return true
    }

    /// 엄마: 완료 대기 → 완료 승인 (시간 제한 없음)
    @discardableResult
    func momApprove(id: String, date: Date = Date()) -> Bool {
        let key = activeScheduleKey(from: date)
        guard let item = visibleItems(from: date).first(where: { $0.id == id }),
              item.isAwaitingMomApproval else { return false }
        guard mutateItem(id: id, in: key, mutate: {
            $0.pendingApproval = false
            $0.completed = true
        }) else { return false }
        save()
        maybeCelebrate(date: date)
        return true
    }

    /// 엄마: 완료 대기 → 거절 (미완료 상태로 복원)
    @discardableResult
    func momReject(id: String, date: Date = Date()) -> Bool {
        let key = activeScheduleKey(from: date)
        guard let item = visibleItems(from: date).first(where: { $0.id == id }),
              item.isAwaitingMomApproval else { return false }
        guard mutateItem(id: id, in: key, mutate: {
            $0.pendingApproval = false
            $0.completed = false
        }) else { return false }
        save()
        return true
    }

    /// 엄마: 오늘 보이는 완료 대기 항목 전체 승인
    @discardableResult
    func momApproveAllPending(date: Date = Date()) -> Int {
        let key = activeScheduleKey(from: date)
        let ids = pendingItems(from: date).map(\.id)
        guard !ids.isEmpty else { return 0 }
        for id in ids {
            _ = mutateItem(id: id, in: key, mutate: {
                $0.pendingApproval = false
                $0.completed = true
            })
        }
        save()
        maybeCelebrate(date: date)
        return ids.count
    }

    func applyReward(give: Int, spend: Int, saveAmount: Int, bankStore: PiggyBankStore, date: Date = Date()) -> Bool {
        let sum = give + spend + saveAmount
        guard sum == TodoCycleHelper.rewardAmount else { return false }
        let key = activeScheduleKey(from: date)
        var changed: [PiggyBankType] = []
        if give > 0 {
            bankStore.deposit(to: .give, amount: give, kind: .todo, note: "할 일 보상")
            changed.append(.give)
        }
        if spend > 0 {
            bankStore.deposit(to: .spend, amount: spend, kind: .todo, note: "할 일 보상")
            changed.append(.spend)
        }
        if saveAmount > 0 {
            bankStore.deposit(to: .save, amount: saveAmount, kind: .todo, note: "할 일 보상")
            changed.append(.save)
        }
        switch key {
        case .weekday: state.weekday.rewardClaimed = true
        case .weekend: state.weekend.rewardClaimed = true
        }
        lastRewardBankTypes = changed
        save()
        pulseToken += 1
        return true
    }

    func allComplete(date: Date = Date()) -> Bool {
        let visible = visibleItems(from: date)
        return hasPublishedSchedule(from: date) && !visible.isEmpty && visible.allSatisfy(\.completed)
    }

    func canClaimReward(date: Date = Date()) -> Bool {
        allComplete(date: date) && !activeSchedule(from: date).rewardClaimed
    }

    func nightMessage(date: Date = Date()) -> (text: String, isSuccess: Bool)? {
        let visible = visibleItems(from: date)
        guard TodoCycleHelper.isLocked(from: date), hasPublishedSchedule(from: date), !visible.isEmpty else { return nil }
        if visible.allSatisfy(\.completed) {
            return (ChildNameSettings.nightSuccess, true)
        }
        if visible.allSatisfy({ $0.completed || $0.isAwaitingMomApproval }) {
            return ("엄마가 확인해 주면 완료돼요", true)
        }
        return (ChildNameSettings.nightEncourage, false)
    }

    private func maybeCelebrate(date: Date) {
        guard canClaimReward(date: date) else { return }
        showCelebration = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.showCelebration = false
            self?.showRewardSheet = true
        }
    }

    private func mutateItem(id: String, in key: TodoScheduleKey, mutate: (inout TodoItem) -> Void) -> Bool {
        switch key {
        case .weekday:
            guard let idx = state.weekday.items.firstIndex(where: { $0.id == id }) else { return false }
            mutate(&state.weekday.items[idx])
        case .weekend:
            guard let idx = state.weekend.items.firstIndex(where: { $0.id == id }) else { return false }
            mutate(&state.weekend.items[idx])
        }
        return true
    }

    private func resetCompletion(for key: TodoScheduleKey) {
        switch key {
        case .weekday:
            for i in state.weekday.items.indices {
                state.weekday.items[i].completed = false
                state.weekday.items[i].pendingApproval = false
            }
            state.weekday.rewardClaimed = false
        case .weekend:
            for i in state.weekend.items.indices {
                state.weekend.items[i].completed = false
                state.weekend.items[i].pendingApproval = false
            }
            state.weekend.rewardClaimed = false
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        AppGroupStorage.setTodoData(data)
        TodoWidgetRefresher.reload()
        TodoReminderScheduler.reschedule(todoStore: self)
    }
}
