import SwiftUI

struct HeartBoardBackground: View {
    var body: some View {
        ZStack {
            HeartShape()
                .fill(Color(hex: "FF6B8A").opacity(0.12))
                .frame(width: 168, height: 152)
                .offset(y: 6)

            HeartShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD4E5"),
                            Color(hex: "FF8FAB"),
                            Color(hex: "FF6B8A"),
                            Color(hex: "E8456A"),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    HeartShape()
                        .stroke(Color(hex: "FF4D7A"), lineWidth: 2.5)
                )
                .frame(width: 164, height: 148)

            HeartShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFF0F5").opacity(0.9),
                            Color(hex: "FFB8D0").opacity(0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 98)
                .offset(y: 8)

            Ellipse()
                .fill(.white.opacity(0.4))
                .frame(width: 36, height: 24)
                .rotationEffect(.degrees(-25))
                .offset(x: -28, y: -18)

            Circle()
                .fill(Color(hex: "FFD4E5").opacity(0.8))
                .frame(width: 8, height: 8)
                .offset(x: -58, y: -42)

            Circle()
                .fill(Color(hex: "FFD4E5").opacity(0.7))
                .frame(width: 6, height: 6)
                .offset(x: 58, y: -38)

            Circle()
                .fill(.white.opacity(0.55))
                .frame(width: 5, height: 5)
                .offset(x: -48, y: -52)

            Image(systemName: "heart.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "FFB8D0").opacity(0.7))
                .offset(x: -52, y: 10)

            Image(systemName: "heart.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "FF8FAB").opacity(0.6))
                .offset(x: 52, y: 18)

            Image(systemName: "sparkle")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.65))
                .offset(x: 42, y: -48)
        }
    }
}

private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.92))
        path.addCurve(
            to: CGPoint(x: w * 0.06, y: h * 0.32),
            control1: CGPoint(x: w * 0.2, y: h * 0.72),
            control2: CGPoint(x: w * 0.06, y: h * 0.52)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.22),
            control1: CGPoint(x: w * 0.06, y: h * 0.12),
            control2: CGPoint(x: w * 0.28, y: h * 0.12)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.94, y: h * 0.32),
            control1: CGPoint(x: w * 0.72, y: h * 0.12),
            control2: CGPoint(x: w * 0.94, y: h * 0.12)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.92),
            control1: CGPoint(x: w * 0.94, y: h * 0.52),
            control2: CGPoint(x: w * 0.8, y: h * 0.72)
        )
        path.closeSubpath()
        return path
    }
}
