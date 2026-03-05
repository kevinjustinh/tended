import SwiftUI

struct ProgressRingView: View {
    var progress: Double   // 0.0 – 1.0
    var size: CGFloat = 64
    var lineWidth: CGFloat = 6

    private var progressColor: Color {
        if progress >= 1.0 { return .successMoss }
        if progress >= 0.5 { return .sageGreen }
        return .warmTan
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.warmSand, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.springCard, value: progress)

            // Center label
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.springCard, value: progress)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 24) {
        ProgressRingView(progress: 0)
        ProgressRingView(progress: 0.4)
        ProgressRingView(progress: 0.75)
        ProgressRingView(progress: 1.0)
    }
    .padding()
    .background(Color.creamWhite)
}
