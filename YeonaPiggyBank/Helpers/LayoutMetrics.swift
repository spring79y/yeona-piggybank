import SwiftUI
import UIKit

enum DeviceLayout {
    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

enum LayoutMetrics {
    /// iPhone: 세그먼트 + 캐러셀 / iPad: 나눔·용돈·저축 3열 동시 표시
    static func usesJarCarousel(width: CGFloat) -> Bool {
        DeviceLayout.isPhone
    }

    static func iPadJarSidePadding(screenWidth: CGFloat) -> CGFloat { 24 }

    static func iPadJarColumnSpacing(screenWidth: CGFloat) -> CGFloat { 16 }

    static func jarCardWidth(screenWidth: CGFloat) -> CGFloat {
        if DeviceLayout.isPhone {
            return min(280, max(220, screenWidth - 56))
        }
        let sidePadding = iPadJarSidePadding(screenWidth: screenWidth)
        let columnSpacing = iPadJarColumnSpacing(screenWidth: screenWidth)
        let columnWidth = (screenWidth - sidePadding * 2 - columnSpacing * 2) / 3
        // 카드 본체 + 좌우 패딩이 열 너비에 맞도록 (패딩 ≈ 14%)
        return max(160, columnWidth / 1.14)
    }

    static func jarSectionHeight(cardWidth: CGFloat) -> CGFloat {
        let scale = max(cardWidth / 200, 1)

        if DeviceLayout.isPhone {
            let cardPadding = max(8, 9 * scale) * 2
            let inner = cardWidth - cardPadding
            let jarGraphic = inner * 0.96 * 0.94
            let textBlock = (24 + 30 + 20) * scale
            let saveExtra = 44 * scale
            let cardHeight = jarGraphic + (8 * scale) + textBlock + saveExtra + cardPadding + 8
            let historyArea: CGFloat = 10 + 38 + 12
            return cardHeight + historyArea
        }

        let jarGraphic = 147 * scale
        let cardPadding = 14 * scale * 2
        let textBlock = (28 + 36 + 24 + 48) * scale
        let cardHeight = jarGraphic + (11 * scale) + textBlock + cardPadding + 12
        let historyArea: CGFloat = 10 + 38 + 12
        return cardHeight + historyArea
    }

    static func appTitleSize(width: CGFloat) -> CGFloat {
        DeviceLayout.isPhone ? 30 : 42
    }

    static func todoBoardHeight(width: CGFloat) -> CGFloat {
        DeviceLayout.isPhone ? min(280, width * 0.72) : 320
    }

    static func todoPostItSize(width: CGFloat) -> CGFloat {
        let boardHeight = todoBoardHeight(width: width)
        if DeviceLayout.isPad {
            return 120
        }
        let base = min(width * 0.30, boardHeight * 0.38)
        return max(88, min(120, base))
    }

    static func nightMessageSize(width: CGFloat) -> CGFloat {
        DeviceLayout.isPhone ? 28 : 45
    }

    static func spinWheelSize(screenWidth: CGFloat, availableHeight: CGFloat? = nil) -> CGFloat {
        let widthBased: CGFloat
        if DeviceLayout.isPhone {
            widthBased = min(260, max(220, screenWidth - 88))
        } else {
            widthBased = min(280, max(240, screenWidth - 160))
        }

        guard let availableHeight else { return widthBased }

        // 헤더·결과·버튼·간격·하단 여백·휠 프레임 여유
        let verticalOverhead: CGFloat = DeviceLayout.isPad ? 360 : 330
        let heightBased = availableHeight - verticalOverhead
        return min(widthBased, max(180, heightBased))
    }
}

struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = CGSize(width: 390, height: 700)

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func trackWidth(_ width: Binding<CGFloat>) -> some View {
        trackSize(width: width, height: .constant(700))
    }

    func trackSize(width: Binding<CGFloat>, height: Binding<CGFloat>) -> some View {
        background {
            GeometryReader { geo in
                Color.clear
                    .preference(key: ViewSizeKey.self, value: geo.size)
            }
        }
        .onPreferenceChange(ViewSizeKey.self) { size in
            width.wrappedValue = size.width
            height.wrappedValue = size.height
        }
    }
}
