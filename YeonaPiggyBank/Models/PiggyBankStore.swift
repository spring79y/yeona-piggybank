import Foundation
import SwiftUI

@MainActor
final class PiggyBankStore: ObservableObject {
    @Published private(set) var banks: [PiggyBank]
    @Published private(set) var hasPassword: Bool
    @Published private(set) var transactions: [PiggyBankTransaction]
    @Published private(set) var saveBonusRatePercent: Int
    @Published private(set) var childLastName: String = ""
    @Published private(set) var childFirstName: String = ""

    private let storageKey = "yeona_piggy_banks"
    private let passwordKey = "yeona_piggy_password"
    private let lastSaveBonusKey = "yeona_last_save_bonus_day"
    private let legacySaveBonusMonthKey = "yeona_last_save_bonus_month"
    private let historyKey = "yeona_transaction_history"
    private let appVersionKey = "yeona_app_version"
    private let currentAppVersion = "2.2"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([PiggyBank].self, from: data) {
            banks = Self.ensureAllTypes(saved)
        } else {
            banks = PiggyBankType.allCases.map {
                PiggyBank(type: $0, balance: 0, goal: $0.defaultGoal)
            }
        }

        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let savedHistory = try? JSONDecoder().decode([PiggyBankTransaction].self, from: historyData) {
            transactions = savedHistory
        } else {
            transactions = []
        }

        if UserDefaults.standard.string(forKey: appVersionKey) != currentAppVersion {
            UserDefaults.standard.set(currentAppVersion, forKey: appVersionKey)
        }

        hasPassword = UserDefaults.standard.string(forKey: passwordKey) != nil
        saveBonusRatePercent = SaveBonusSettings.ratePercent
        reloadChildName()
        migrateSaveBonusTrackingIfNeeded()
        applyDailySaveBonusIfNeeded()
        startDailyBonusTimer()
    }

    func setPassword(_ password: String) {
        guard !password.isEmpty else { return }
        UserDefaults.standard.set(password, forKey: passwordKey)
        hasPassword = true
    }

    func clearPassword() {
        UserDefaults.standard.removeObject(forKey: passwordKey)
        hasPassword = false
    }

    func verifyPassword(_ password: String) -> Bool {
        UserDefaults.standard.string(forKey: passwordKey) == password
    }

    func setSaveBonusRatePercent(_ rate: Int) {
        SaveBonusSettings.ratePercent = rate
        saveBonusRatePercent = SaveBonusSettings.ratePercent
    }

    func setChildName(lastName: String, firstName: String) {
        ChildNameSettings.save(lastName: lastName, firstName: firstName)
        reloadChildName()
    }

    func reloadChildName() {
        childLastName = ChildNameSettings.lastName
        childFirstName = ChildNameSettings.firstName
    }

    var appTitle: String {
        ChildNameSettings.appTitle
    }

    func bank(for type: PiggyBankType) -> PiggyBank {
        banks.first { $0.type == type }!
    }

    func history(for type: PiggyBankType) -> [PiggyBankTransaction] {
        transactions.filter { $0.bankType == type }
    }

    func deposit(
        to type: PiggyBankType,
        amount: Int,
        kind: TransactionKind = .deposit,
        note: String? = nil
    ) {
        guard amount > 0, let index = banks.firstIndex(where: { $0.type == type }) else { return }
        banks[index].balance += amount
        recordTransaction(
            bankType: type,
            kind: kind,
            amount: amount,
            balanceAfter: banks[index].balance,
            note: note
        )
        save()
    }

    func withdraw(from type: PiggyBankType, amount: Int, note: String? = nil) {
        guard amount > 0, let index = banks.firstIndex(where: { $0.type == type }) else { return }
        banks[index].balance = max(0, banks[index].balance - amount)
        recordTransaction(
            bankType: type,
            kind: .withdraw,
            amount: amount,
            balanceAfter: banks[index].balance,
            note: note
        )
        save()
    }

    @discardableResult
    func withdrawSaveToSpend(amount: Int) -> Bool {
        guard MonthEndHelper.canWithdrawSave() else { return false }
        guard amount > 0,
              let saveIndex = banks.firstIndex(where: { $0.type == .save }),
              let spendIndex = banks.firstIndex(where: { $0.type == .spend }),
              banks[saveIndex].balance >= amount else { return false }

        banks[saveIndex].balance -= amount
        recordTransaction(
            bankType: .save,
            kind: .withdraw,
            amount: amount,
            balanceAfter: banks[saveIndex].balance,
            note: "용돈으로 이동"
        )

        banks[spendIndex].balance += amount
        recordTransaction(
            bankType: .spend,
            kind: .deposit,
            amount: amount,
            balanceAfter: banks[spendIndex].balance,
            note: "저축에서 이동"
        )

        save()
        return true
    }

    func resetAll() {
        banks = PiggyBankType.allCases.map {
            PiggyBank(type: $0, balance: 0, goal: $0.defaultGoal)
        }
        transactions = []
        ChildNameSettings.clear()
        childLastName = ""
        childFirstName = ""
        SaveBonusSettings.resetToDefault()
        saveBonusRatePercent = SaveBonusSettings.ratePercent
        UserDefaults.standard.removeObject(forKey: lastSaveBonusKey)
        UserDefaults.standard.removeObject(forKey: legacySaveBonusMonthKey)
        seedLastBonusPaidDay(before: Date())
        save()
        saveHistory()
    }

    func applyDailySaveBonusIfNeeded(at date: Date = Date()) {
        guard let saveIndex = banks.firstIndex(where: { $0.type == .save }) else { return }

        guard let lastPaidDay = loadLastBonusPaidDay() else {
            seedLastBonusPaidDay(before: date)
            return
        }

        let calendar = Calendar.current
        var cursor = lastPaidDay
        var paidThrough: Date?

        while let nextDay = SaveInterestHelper.nextDay(after: cursor) {
            guard let payoutAt = SaveInterestHelper.payoutTime(on: nextDay) else { break }
            guard date >= payoutAt else { break }

            let bonus = SaveBonusSettings.dailyInterestAmount(
                for: banks[saveIndex].balance,
                rate: saveBonusRatePercent,
                on: nextDay
            )
            if bonus > 0 {
                banks[saveIndex].balance += bonus
                recordTransaction(
                    bankType: .save,
                    kind: .bonus,
                    amount: bonus,
                    balanceAfter: banks[saveIndex].balance,
                    note: "일일 투자 수익",
                    date: payoutAt
                )
            }

            cursor = nextDay
            paidThrough = nextDay
        }

        if let paidThrough {
            UserDefaults.standard.set(SaveInterestHelper.dateKey(from: paidThrough), forKey: lastSaveBonusKey)
            save()
        }
    }

    private func loadLastBonusPaidDay() -> Date? {
        guard let key = UserDefaults.standard.string(forKey: lastSaveBonusKey) else { return nil }
        return SaveInterestHelper.parseDateKey(key).map { Calendar.current.startOfDay(for: $0) }
    }

    private func seedLastBonusPaidDay(before date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let seed = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        UserDefaults.standard.set(SaveInterestHelper.dateKey(from: seed), forKey: lastSaveBonusKey)
    }

    private func migrateSaveBonusTrackingIfNeeded() {
        guard UserDefaults.standard.string(forKey: lastSaveBonusKey) == nil else { return }
        if UserDefaults.standard.string(forKey: legacySaveBonusMonthKey) != nil {
            UserDefaults.standard.removeObject(forKey: legacySaveBonusMonthKey)
        }
        seedLastBonusPaidDay(before: Date())
    }

    private func recordTransaction(
        bankType: PiggyBankType,
        kind: TransactionKind,
        amount: Int,
        balanceAfter: Int,
        note: String?,
        date: Date = Date()
    ) {
        let entry = PiggyBankTransaction(
            id: UUID(),
            bankType: bankType,
            kind: kind,
            amount: amount,
            balanceAfter: balanceAfter,
            note: note,
            date: date
        )
        transactions.insert(entry, at: 0)
        saveHistory()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(banks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(transactions) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    func tickScheduledTasks(at date: Date = Date()) {
        applyDailySaveBonusIfNeeded(at: date)
    }

    private func startDailyBonusTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickScheduledTasks()
            }
        }
    }

    private static func ensureAllTypes(_ saved: [PiggyBank]) -> [PiggyBank] {
        var result = saved
        for type in PiggyBankType.allCases where !result.contains(where: { $0.type == type }) {
            result.append(PiggyBank(type: type, balance: 0, goal: type.defaultGoal))
        }
        return PiggyBankType.allCases.compactMap { type in
            result.first { $0.type == type }
        }
    }
}
