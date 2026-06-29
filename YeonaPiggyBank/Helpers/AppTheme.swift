import SwiftUI
import UIKit

enum AppTheme {
    static let backgroundTop = adaptive(light: "FFF5F7", dark: "1C1824")
    static let backgroundMid = adaptive(light: "F0F8FF", dark: "141C2A")
    static let backgroundBottom = adaptive(light: "FFF9E6", dark: "1A1812")

    static let screenBackground = adaptive(light: "F2F2F2", dark: "000000")
    static let cardBackground = adaptive(light: "FFFFFF", dark: "1C1C1E")
    static let elevatedCardBackground = adaptive(light: "FFFFFF", dark: "2C2C2E")

    static let primaryText = adaptive(light: "2D3436", dark: "F2F2F7")
    static let secondaryText = adaptive(light: "636E72", dark: "AEAEB2")
    static let subtitleText = adaptive(light: "666666", dark: "98989D")
    static let jarTitleText = adaptive(light: "222222", dark: "F2F2F7")

    static let fieldBackground = adaptive(light: "FFFFFF", dark: "2C2C2E")
    static let fieldBorder = adaptive(light: "D1D5DB", dark: "48484A")
    static let fieldText = adaptive(light: "191919", dark: "F2F2F7")

    static let separator = adaptive(light: "E5E5EA", dark: "38383A")
    static let chevron = adaptive(light: "C7C7CC", dark: "636366")
    static let mutedLabel = adaptive(light: "8E8E93", dark: "98989D")

    static var backgroundGradient: [Color] {
        [backgroundTop, backgroundMid, backgroundBottom]
    }

    private static func adaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? uiColor(hex: dark) : uiColor(hex: light)
        })
    }

    private static func uiColor(hex: String) -> UIColor {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)
        return UIColor(
            red: CGFloat((int >> 16) & 0xFF) / 255,
            green: CGFloat((int >> 8) & 0xFF) / 255,
            blue: CGFloat(int & 0xFF) / 255,
            alpha: 1
        )
    }
}
