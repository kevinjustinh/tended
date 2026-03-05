import SwiftUI
import Lottie

/// Lottie-backed confetti celebration overlay.
/// Usage: overlay this on any view and bind `isVisible` to trigger it.
struct ConfettiView: View {
    var isVisible: Bool
    var lottieName: String = "confetti"

    var body: some View {
        if isVisible {
            LottieViewRepresentable(name: lottieName)
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .transition(.opacity)
        }
    }
}

/// UIViewRepresentable bridge for Lottie LottieAnimationView
struct LottieViewRepresentable: UIViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .playOnce
    var animationSpeed: CGFloat = 1.0

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: name)
        view.contentMode = .scaleAspectFill
        view.loopMode = loopMode
        view.animationSpeed = animationSpeed
        view.play()
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}

/// Standalone Lottie wrapper for the paw-draw onboarding animation
struct LottiePawView: View {
    var body: some View {
        LottieViewRepresentable(name: "paw-draw", loopMode: .loop)
            .frame(width: 160, height: 160)
    }
}

#Preview {
    ZStack {
        Color.creamWhite.ignoresSafeArea()
        ConfettiView(isVisible: true)
    }
}
