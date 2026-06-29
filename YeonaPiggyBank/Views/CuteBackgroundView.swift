import SwiftUI

struct CuteBackgroundView: View {
    private struct Decoration: Identifiable {
        let id: Int
        let emoji: String
        let xRatio: CGFloat
        let yRatio: CGFloat
        let size: CGFloat
        let opacity: Double
        let duration: Double
        let delay: Double
    }

    private let decorations: [Decoration] = [
        Decoration(id: 0, emoji: "🐱", xRatio: 0.08, yRatio: 0.12, size: 44, opacity: 0.35, duration: 4.2, delay: 0),
        Decoration(id: 1, emoji: "🐈", xRatio: 0.88, yRatio: 0.18, size: 38, opacity: 0.3, duration: 5.0, delay: 0.5),
        Decoration(id: 2, emoji: "😺", xRatio: 0.15, yRatio: 0.72, size: 36, opacity: 0.28, duration: 4.8, delay: 1.0),
        Decoration(id: 3, emoji: "🐾", xRatio: 0.82, yRatio: 0.78, size: 32, opacity: 0.25, duration: 3.6, delay: 0.3),
        Decoration(id: 4, emoji: "❤️", xRatio: 0.25, yRatio: 0.28, size: 28, opacity: 0.4, duration: 3.0, delay: 0.2),
        Decoration(id: 5, emoji: "💕", xRatio: 0.72, yRatio: 0.35, size: 30, opacity: 0.35, duration: 3.5, delay: 0.8),
        Decoration(id: 6, emoji: "💖", xRatio: 0.05, yRatio: 0.48, size: 26, opacity: 0.3, duration: 4.0, delay: 1.2),
        Decoration(id: 7, emoji: "⭐", xRatio: 0.92, yRatio: 0.52, size: 30, opacity: 0.45, duration: 2.8, delay: 0.4),
        Decoration(id: 8, emoji: "✨", xRatio: 0.48, yRatio: 0.08, size: 24, opacity: 0.4, duration: 2.5, delay: 0.6),
        Decoration(id: 9, emoji: "🌟", xRatio: 0.58, yRatio: 0.88, size: 28, opacity: 0.38, duration: 3.2, delay: 0.9),
        Decoration(id: 10, emoji: "⭐", xRatio: 0.35, yRatio: 0.92, size: 22, opacity: 0.32, duration: 3.8, delay: 1.5),
        Decoration(id: 11, emoji: "❤️", xRatio: 0.65, yRatio: 0.62, size: 24, opacity: 0.28, duration: 4.5, delay: 0.7),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RainbowArc()
                    .opacity(0.25)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.15)

                ForEach(decorations) { deco in
                    FloatingEmoji(
                        emoji: deco.emoji,
                        size: deco.size,
                        opacity: deco.opacity,
                        duration: deco.duration,
                        delay: deco.delay
                    )
                    .position(
                        x: geo.size.width * deco.xRatio,
                        y: geo.size.height * deco.yRatio
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct RainbowArc: View {
    private let colors: [Color] = [
        Color(hex: "FF6B8A"),
        Color(hex: "FFB347"),
        Color(hex: "FFE066"),
        Color(hex: "4ECDC4"),
        Color(hex: "6C9BFF"),
        Color(hex: "C77DFF"),
    ]

    var body: some View {
        ZStack {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                Circle()
                    .trim(from: 0.25, to: 0.75)
                    .stroke(color, lineWidth: 8)
                    .rotationEffect(.degrees(180))
                    .frame(width: 280 - CGFloat(index * 18), height: 280 - CGFloat(index * 18))
            }
        }
        .frame(width: 300, height: 160)
    }
}

private struct FloatingEmoji: View {
    let emoji: String
    let size: CGFloat
    let opacity: Double
    let duration: Double
    let delay: Double

    @State private var floating = false

    var body: some View {
        Text(emoji)
            .font(.system(size: size))
            .opacity(opacity)
            .offset(y: floating ? -8 : 8)
            .rotationEffect(.degrees(floating ? 5 : -5))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    floating = true
                }
            }
    }
}
