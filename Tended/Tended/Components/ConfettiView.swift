import SwiftUI

// MARK: - Confetti overlay (pure SwiftUI, no external files needed)

struct ConfettiView: View {
    var isVisible: Bool

    var body: some View {
        if isVisible {
            ConfettiCanvas()
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .transition(.opacity)
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let speed: Double
    let sway: Double
    let delay: Double
}

private struct ConfettiCanvas: View {
    private let particles: [ConfettiParticle] = (0..<80).map { i in
        ConfettiParticle(
            x: CGFloat.random(in: 0...1),
            color: [
                Color.sageGreen, Color.warmTan, Color.alertAmber,
                Color(hex: "#E87070"), Color(hex: "#70A8E8"), Color.successMoss
            ][i % 6],
            size: CGFloat.random(in: 6...12),
            rotation: Double.random(in: 0...360),
            speed: Double.random(in: 0.6...1.0),
            sway: Double.random(in: -60...60),
            delay: Double.random(in: 0...0.4)
        )
    }

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 0.5)
                    .rotationEffect(.degrees(animate ? p.rotation + 360 : p.rotation))
                    .position(
                        x: geo.size.width * p.x + (animate ? p.sway : 0),
                        y: animate ? geo.size.height + 20 : -20
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeIn(duration: p.speed * 1.2).delay(p.delay),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

/// Animated paw used in onboarding (pure SwiftUI fallback)
struct LottiePawView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6

    var body: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 80, weight: .light))
            .foregroundStyle(Color.sageGreen)
            .scaleEffect(scale)
            .opacity(opacity)
            .frame(width: 160, height: 160)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    scale = 1.1
                    opacity = 1.0
                }
            }
    }
}

#Preview {
    ZStack {
        Color.creamWhite.ignoresSafeArea()
        ConfettiView(isVisible: true)
    }
}
