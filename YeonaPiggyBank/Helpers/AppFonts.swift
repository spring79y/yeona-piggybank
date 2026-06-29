import SwiftUI
import UIKit

enum AppFonts {
    /// 나눔손글씨 펜 (SIL OFL)
    private static let postItCandidates = [
        "나눔손글씨펜-Regular",
        "NanumPenScript",
    ]

    static func postItHandwriting(size: CGFloat) -> Font {
        for name in postItCandidates {
            if UIFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
        }
        return .system(size: size, weight: .medium, design: .rounded)
    }
}
