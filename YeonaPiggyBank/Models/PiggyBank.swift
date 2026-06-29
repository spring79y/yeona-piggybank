import Foundation

enum PiggyBankType: String, CaseIterable, Identifiable, Codable {
    case give
    case spend
    case save

    var id: String { rawValue }

    var name: String {
        switch self {
        case .give: return "나눔"
        case .spend: return "용돈"
        case .save: return "저축"
        }
    }

    var subtitle: String {
        switch self {
        case .give: return "기부하기"
        case .spend: return "쓸 수 있는 돈"
        case .save: return "투자하기"
        }
    }

    var icon: String {
        switch self {
        case .give: return "heart.fill"
        case .spend: return "bag.fill"
        case .save: return "building.columns.fill"
        }
    }

    var emoji: String {
        switch self {
        case .give: return "❤️"
        case .spend: return "🛍️"
        case .save: return "🏦"
        }
    }

    var colorHex: String {
        switch self {
        case .give: return "FF6B8A"
        case .spend: return "FFB347"
        case .save: return "4ECDC4"
        }
    }

    var defaultGoal: Int { 100_000 }
}

struct PiggyBank: Identifiable, Codable, Equatable {
    let type: PiggyBankType
    var balance: Int
    var goal: Int

    var id: String { type.id }

    var fillRatio: Double {
        guard goal > 0 else { return 0 }
        return min(Double(balance) / Double(goal), 1.0)
    }

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: balance)) ?? "0") + "원"
    }
}
