import CoreGraphics
import Foundation

struct TodoPostItLayout: Identifiable {
    let id: Int
    let left: CGFloat
    let top: CGFloat
    let rotate: Double
    let colorName: String

    static let layouts: [TodoPostItLayout] = [
        .init(id: 0, left: 0.05, top: 0.08, rotate: -5, colorName: "yellow"),
        .init(id: 1, left: 0.28, top: 0.05, rotate: 4, colorName: "pink"),
        .init(id: 2, left: 0.51, top: 0.10, rotate: -3, colorName: "mint"),
        .init(id: 3, left: 0.74, top: 0.07, rotate: 3, colorName: "blue"),
        .init(id: 4, left: 0.14, top: 0.32, rotate: 3, colorName: "peach"),
        .init(id: 5, left: 0.38, top: 0.28, rotate: -4, colorName: "yellow"),
        .init(id: 6, left: 0.62, top: 0.34, rotate: 5, colorName: "pink"),
        .init(id: 7, left: 0.82, top: 0.30, rotate: -2, colorName: "mint"),
        .init(id: 8, left: 0.08, top: 0.54, rotate: 2, colorName: "blue"),
        .init(id: 9, left: 0.32, top: 0.50, rotate: -3, colorName: "peach"),
        .init(id: 10, left: 0.56, top: 0.56, rotate: 4, colorName: "yellow"),
        .init(id: 11, left: 0.78, top: 0.52, rotate: -2, colorName: "pink"),
    ]
}
