import Foundation

enum TodoCycleHelper {
    static let rewardAmount = 1000
    static let resetHour = 6
    static let deadlineHour = 21

    static func cycleDateKey(from date: Date = Date()) -> String {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        if (components.hour ?? 0) < resetHour {
            if let d = calendar.date(from: components),
               let prev = calendar.date(byAdding: .day, value: -1, to: d) {
                return dayKey(from: prev)
            }
        }
        return dayKey(from: date)
    }

    static func dayKey(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }

    static func isWeekend(from date: Date = Date()) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    static func activeScheduleKey(from date: Date = Date()) -> TodoScheduleKey {
        isWeekend(from: date) ? .weekend : .weekday
    }

    static func isActivePeriod(from date: Date = Date()) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= resetHour && hour < deadlineHour
    }

    static func isLocked(from date: Date = Date()) -> Bool {
        !isActivePeriod(from: date)
    }

    static func countdownText(from date: Date = Date()) -> String {
        guard isActivePeriod(from: date) else { return "0시 0분 0초" }
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = deadlineHour
        components.minute = 0
        components.second = 0
        guard let deadline = calendar.date(from: components) else { return "0시 0분 0초" }
        let diff = max(0, Int(deadline.timeIntervalSince(date)))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        return "\(hours)시 \(minutes)분 \(seconds)초"
    }
}

enum TodoScheduleKey: String, Codable, CaseIterable, Identifiable {
    case weekday
    case weekend

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekday: return "평일"
        case .weekend: return "주말"
        }
    }
}

enum TodoWeekdayHelper {
    /// ISO weekday: 월=1 … 일=7
    static let weekdayOptions: [(value: Int, label: String)] = [
        (1, "월"), (2, "화"), (3, "수"), (4, "목"), (5, "금"),
    ]
    static let allWeekdays: Set<Int> = [1, 2, 3, 4, 5]

    static func isoWeekday(from date: Date = Date()) -> Int {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar.component(.weekday, from: date)
    }

    static func isoWeekday(fromJavaScriptDay jsDay: Int) -> Int {
        jsDay == 0 ? 7 : jsDay
    }

    static func label(for isoWeekday: Int) -> String {
        weekdayOptions.first(where: { $0.value == isoWeekday })?.label ?? "?"
    }

    static func labels(for weekdays: [Int]) -> String {
        let sorted = weekdays.sorted()
        if Set(sorted) == allWeekdays { return "월~금" }
        return sorted.map { label(for: $0) }.joined(separator: "·")
    }
}
