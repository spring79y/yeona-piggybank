import Foundation

enum TransactionKind: String, Codable {
    case deposit
    case withdraw
    case bonus
    case wheel
    case todo

    var label: String {
        switch self {
        case .deposit: return "입금"
        case .withdraw: return "출금"
        case .bonus: return "투자 수익"
        case .wheel: return "돌림판"
        case .todo: return "할 일 보상"
        }
    }

    var isCredit: Bool {
        switch self {
        case .deposit, .bonus, .wheel, .todo: return true
        case .withdraw: return false
        }
    }
}

struct PiggyBankTransaction: Identifiable, Codable, Equatable {
    let id: UUID
    let bankType: PiggyBankType
    let kind: TransactionKind
    let amount: Int
    let balanceAfter: Int
    let note: String?
    let date: Date

    var signedAmountText: String {
        let prefix = kind.isCredit ? "+" : "-"
        return prefix + amount.formatted + "원"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension Int {
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
