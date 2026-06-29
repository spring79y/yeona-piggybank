import Foundation

enum MonthEndHelper {
    static func yearMonth(from date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return String(format: "%04d-%02d", year, month)
    }

    static func nextYearMonth(_ ym: String) -> String {
        let parts = ym.split(separator: "-")
        guard parts.count == 2,
              var year = Int(parts[0]),
              var month = Int(parts[1]) else { return ym }
        month += 1
        if month > 12 {
            month = 1
            year += 1
        }
        return String(format: "%04d-%02d", year, month)
    }

    static func endOfMonth(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year,
              let month = components.month,
              let startOfNextMonth = calendar.date(from: DateComponents(year: year, month: month + 1, day: 1)),
              let endOfMonth = calendar.date(byAdding: .second, value: -1, to: startOfNextMonth) else {
            return date
        }
        return endOfMonth
    }

    static func timeUntilMonthEnd(from date: Date = Date()) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let interval = max(0, endOfMonth(from: date).timeIntervalSince(date))
        let total = Int(interval)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return (days, hours, minutes, seconds)
    }

    static func formattedCountdown(from date: Date = Date()) -> String {
        let t = timeUntilMonthEnd(from: date)
        return "\(t.days)일 \(t.hours)시 \(t.minutes)분 \(t.seconds)초"
    }

    static func canWithdrawSave(from date: Date = Date()) -> Bool {
        let day = Calendar.current.component(.day, from: date)
        return day >= 1 && day <= 5
    }
}
