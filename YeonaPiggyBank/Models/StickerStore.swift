import Foundation
import SwiftUI

struct WheelPrize: Identifiable, Equatable {
    let id: String
    let label: String
    let color: Color
    let spendAmount: Int?
    let isToyStore: Bool

    var shortLabel: String {
        switch id {
        case "1000": return "1천"
        case "2000": return "2천"
        case "3000": return "3천"
        case "toys": return "토이저러스"
        case "blank": return "다음에!"
        default: return label
        }
    }

    var resultTitle: String {
        switch id {
        case "blank": return "다음에 도전해요!"
        default: return "\(label) 당첨!"
        }
    }

    var wheelEmoji: String {
        switch id {
        case "1000", "2000", "3000": return "💰"
        case "toys": return "🧸"
        default: return "🍀"
        }
    }

    /// 용돈 칸: 주머니 이모지 개수 (1천=1, 2천=2, 3천=3)
    var moneyBagCount: Int? {
        switch id {
        case "1000": return 1
        case "2000": return 2
        case "3000": return 3
        default: return nil
        }
    }

    var sliceColors: (top: Color, bottom: Color, stroke: Color) {
        switch id {
        case "1000": return (Color(hex: "FF8FA8"), Color(hex: "FF6B8A"), Color(hex: "E84A6F"))
        case "2000": return (Color(hex: "FFCA70"), Color(hex: "FFB347"), Color(hex: "E89400"))
        case "3000": return (Color(hex: "6EE7DE"), Color(hex: "4ECDC4"), Color(hex: "2BA89E"))
        case "toys": return (Color(hex: "C49AE8"), Color(hex: "9B59B6"), Color(hex: "7B3FA0"))
        default: return (Color(hex: "CFD8DC"), Color(hex: "B0BEC5"), Color(hex: "90A4AE"))
        }
    }

    static let all: [WheelPrize] = [
        WheelPrize(id: "1000", label: "1천원", color: Color(hex: "FF6B8A"), spendAmount: 1000, isToyStore: false),
        WheelPrize(id: "2000", label: "2천원", color: Color(hex: "FFB347"), spendAmount: 2000, isToyStore: false),
        WheelPrize(id: "3000", label: "3천원", color: Color(hex: "4ECDC4"), spendAmount: 3000, isToyStore: false),
        WheelPrize(id: "toys", label: "토이저러스가기", color: Color(hex: "9B59B6"), spendAmount: nil, isToyStore: true),
        WheelPrize(id: "blank", label: "꽝", color: Color(hex: "AAAAAA"), spendAmount: nil, isToyStore: false),
    ]
}

@MainActor
final class StickerStore: ObservableObject {
    static let boardCount = 10
    static let palette = ["⭐", "🌟", "💖", "🌸", "🎀", "🏆", "👍", "🌈", "🦋", "🍀", "🎉", "💐", "🌺", "🌻", "🎈"]

    @Published private(set) var placedStickers: [Int: String]
    @Published private(set) var stickerQuotaRemaining: Int
    @Published private(set) var wheelRewardPending: Bool
    @Published private(set) var wheelSpun: Bool

    private let storageKey = "yeona_sticker_boards"

    private struct PersistedState: Codable {
        var placed: [String: String]
        var quotaRemaining: Int
        var wheelRewardPending: Bool
        var wheelSpun: Bool
    }

    init() {
        var loadedStickers: [Int: String] = [:]
        var loadedQuota = 0
        var loadedPending = false
        var loadedSpun = false

        if let data = UserDefaults.standard.data(forKey: storageKey),
           let state = try? JSONDecoder().decode(PersistedState.self, from: data) {
            loadedStickers = state.placed.compactMapKeys { Int($0) }
            loadedQuota = state.quotaRemaining
            loadedPending = state.wheelRewardPending
            loadedSpun = state.wheelSpun
        } else if let data = UserDefaults.standard.data(forKey: storageKey),
                  let legacy = try? JSONDecoder().decode([String: String].self, from: data) {
            loadedStickers = legacy.compactMapKeys { Int($0) }
            loadedPending = loadedStickers.count >= Self.boardCount
        }

        placedStickers = loadedStickers
        stickerQuotaRemaining = loadedQuota
        wheelRewardPending = loadedPending
        wheelSpun = loadedSpun

        if placedStickers.count >= Self.boardCount, !wheelRewardPending, !wheelSpun {
            wheelRewardPending = true
            persist()
        }
    }

    var filledCount: Int { placedStickers.count }
    var isComplete: Bool { filledCount >= Self.boardCount }
    var canPlace: Bool { stickerQuotaRemaining > 0 }
    var canOpenWheel: Bool { wheelRewardPending }

    func sticker(for board: Int) -> String? {
        placedStickers[board]
    }

    func grantQuota(_ count: Int) {
        guard count > 0 else { return }
        stickerQuotaRemaining += count
        persist()
    }

    func markWheelRewardPending() {
        guard isComplete else { return }
        wheelRewardPending = true
        persist()
    }

    func markWheelSpun() {
        wheelSpun = true
        persist()
    }

    func finishWheelReward() {
        wheelRewardPending = false
        wheelSpun = false
        resetBoards()
    }

    func place(sticker: String, on board: Int) -> Bool {
        guard canPlace else { return false }
        guard board >= 0, board < Self.boardCount else { return false }
        guard placedStickers[board] == nil else { return false }
        placedStickers[board] = sticker
        stickerQuotaRemaining -= 1
        persist()
        return true
    }

    func remove(from board: Int) {
        guard placedStickers[board] != nil else { return }
        placedStickers.removeValue(forKey: board)
        stickerQuotaRemaining += 1
        persist()
    }

    func resetBoards() {
        placedStickers = [:]
        stickerQuotaRemaining = 0
        persist()
    }

    func resetAll() {
        placedStickers = [:]
        stickerQuotaRemaining = 0
        wheelRewardPending = false
        wheelSpun = false
        persist()
    }

    private func persist() {
        let state = PersistedState(
            placed: placedStickers.mapKeys { String($0) },
            quotaRemaining: stickerQuotaRemaining,
            wheelRewardPending: wheelRewardPending,
            wheelSpun: wheelSpun
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }

    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        Dictionary<T, Value>(uniqueKeysWithValues: compactMap { key, value in
            transform(key).map { ($0, value) }
        })
    }
}
