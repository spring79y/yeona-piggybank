import Foundation

enum SaveInterestHelper {
    /// 매일 밤 9시 이자 지급
    static let payoutHour = 21

    static func dateKey(from date: Date) -> String {
        let calendar = Calendar.current
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let d = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func parseDateKey(_ key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else { return nil }
        return Calendar.current.date(from: DateComponents(year: y, month: m, day: d))
    }

    static func daysInMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30
    }

    static func payoutTime(on day: Date) -> Date? {
        let start = Calendar.current.startOfDay(for: day)
        return Calendar.current.date(bySettingHour: payoutHour, minute: 0, second: 0, of: start)
    }

    static func nextDay(after date: Date) -> Date? {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: date))
    }

    /// 월이율을 해당 월 일수로 나눈 하루 이자 (10원 단위 반올림)
    static func dailyInterestAmount(
        for balance: Int,
        monthlyRatePercent: Int,
        on date: Date
    ) -> Int {
        guard balance > 0, monthlyRatePercent > 0 else { return 0 }
        let days = daysInMonth(for: date)
        guard days > 0 else { return 0 }
        let raw = Double(balance) * Double(monthlyRatePercent) / 100.0 / Double(days)
        return roundToTenWon(raw)
    }

    static func roundToTenWon(_ amount: Double) -> Int {
        Int((amount / 10.0).rounded() * 10)
    }

    static func timeUntilNextPayout(from date: Date = Date()) -> (hours: Int, minutes: Int, seconds: Int) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: date)
        guard let todayPayout = payoutTime(on: todayStart) else {
            return (0, 0, 0)
        }

        let target: Date
        if date < todayPayout {
            target = todayPayout
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart),
                  let tomorrowPayout = payoutTime(on: tomorrow) {
            target = tomorrowPayout
        } else {
            return (0, 0, 0)
        }

        let interval = max(0, target.timeIntervalSince(date))
        let total = Int(interval)
        return (total / 3600, (total % 3600) / 60, total % 60)
    }

    static func formattedCountdownToPayout(from date: Date = Date()) -> String {
        let t = timeUntilNextPayout(from: date)
        return "\(t.hours)시 \(t.minutes)분 \(t.seconds)초"
    }
}
