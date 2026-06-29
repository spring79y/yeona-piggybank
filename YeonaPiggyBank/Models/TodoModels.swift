import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    let id: String
    var text: String
    var completed: Bool
    /// 아이가 해냈다고 표시했지만 엄마 승인 전
    var pendingApproval: Bool
    /// ISO weekday (월=1 … 금=5). nil/empty = 월~금 전체
    var weekdays: [Int]?

    init(
        id: String,
        text: String,
        completed: Bool,
        pendingApproval: Bool = false,
        weekdays: [Int]? = nil
    ) {
        self.id = id
        self.text = text
        self.completed = completed
        self.pendingApproval = pendingApproval
        self.weekdays = weekdays
    }

    enum CodingKeys: String, CodingKey {
        case id, text, completed, pendingApproval, weekdays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        completed = try container.decode(Bool.self, forKey: .completed)
        pendingApproval = try container.decodeIfPresent(Bool.self, forKey: .pendingApproval) ?? false
        weekdays = try container.decodeIfPresent([Int].self, forKey: .weekdays)
    }

    var effectiveWeekdays: [Int] {
        if let weekdays, !weekdays.isEmpty {
            return weekdays.sorted()
        }
        return Array(TodoWeekdayHelper.allWeekdays).sorted()
    }

    var isAwaitingMomApproval: Bool {
        pendingApproval && !completed
    }

    func isActive(on date: Date = Date(), scheduleKey: TodoScheduleKey) -> Bool {
        if scheduleKey == .weekend { return true }
        return effectiveWeekdays.contains(TodoWeekdayHelper.isoWeekday(from: date))
    }
}

struct TodoSchedule: Codable, Equatable {
    var items: [TodoItem] = []
    var published: Bool = false
    var rewardClaimed: Bool = false
}

struct TodoState: Codable, Equatable {
    var resetDateKey: String
    var weekday: TodoSchedule
    var weekend: TodoSchedule
}
