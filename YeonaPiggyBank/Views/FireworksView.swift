import SwiftUI

struct FireworksView: View {
    @State private var particles: [FireworkParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                spawn(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func spawn(in size: CGSize) {
        let emojis = ["🎆", "🎇", "✨", "⭐", "🌟", "💖", "🎉", "🌈"]
        particles = (0..<40).map { i in
            FireworkParticle(
                id: i,
                emoji: emojis[i % emojis.count],
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height * 0.7)
                ),
                size: CGFloat.random(in: 16...36),
                opacity: Double.random(in: 0.5...1.0)
            )
        }
        withAnimation(.easeOut(duration: 2.5)) {
            for i in particles.indices {
                particles[i].opacity = 0
                particles[i].position.y += CGFloat.random(in: 40...120)
            }
        }
    }
}

private struct FireworkParticle: Identifiable {
    let id: Int
    let emoji: String
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
}
