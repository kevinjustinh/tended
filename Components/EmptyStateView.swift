import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Get Started"

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.sageGreen.opacity(0.7))

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.sectionHeader())
                    .foregroundStyle(Color.textPrimary)

                Text(message)
                    .font(.bodyText())
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            if let action {
                Button(action: action) {
                    Label(actionLabel, systemImage: "plus")
                        .font(.cardTitle())
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(Color.sageGreen, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
}

// MARK: - Presets

extension EmptyStateView {
    static func allDone() -> EmptyStateView {
        EmptyStateView(
            systemImage: "pawprint.fill",
            title: "All done!",
            message: "Your pets are taken care of \u{1F43E}"
        )
    }

    static func noPets(addAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "pawprint",
            title: "No pets yet",
            message: "Add your first pet to start tracking their care.",
            action: addAction,
            actionLabel: "Add a Pet"
        )
    }

    static func noTasks(addAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "checklist",
            title: "No tasks yet",
            message: "Add tasks to keep track of your pet's routine.",
            action: addAction,
            actionLabel: "Add a Task"
        )
    }
}

#Preview {
    EmptyStateView.allDone()
        .background(Color.creamWhite)
}
