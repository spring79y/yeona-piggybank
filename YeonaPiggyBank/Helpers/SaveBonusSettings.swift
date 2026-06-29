import Foundation

enum SaveBonusSettings {
    static let storageKey = "yeona_save_bonus_rate"
    static let defaultRate = 50
    static let allowedRates = Array(stride(from: 10, through: 100, by: 10))

    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    static var ratePercent: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: storageKey)
            if stored == 0 { return defaultRate }
            return allowedRates.contains(stored) ? stored : defaultRate
        }
        set {
            let clamped = allowedRates.contains(newValue) ? newValue : defaultRate
            UserDefaults.standard.set(clamped, forKey: storageKey)
        }
    }

    /// 월이율 기준 하루 이자
    static func dailyInterestAmount(
        for balance: Int,
        rate: Int? = nil,
        on date: Date = Date()
    ) -> Int {
        SaveInterestHelper.dailyInterestAmount(
            for: balance,
            monthlyRatePercent: rate ?? ratePercent,
            on: date
        )
    }
}
