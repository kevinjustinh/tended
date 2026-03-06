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
    static func allDone(petName: String? = nil) -> EmptyStateView {
        let name = petName ?? "your pet"
        let messages = [
            "Tasks complete. Your pet approves. Probably.",
            "You fed me, walked me, and didn't forget my meds. I suppose you may stay.",
            "Nothing to do here. Go stare at your pet for a while.",
            "All tasks complete. Your pet has filed a formal 'good job' with the relevant authorities.",
            "That's a wrap! \(name.prefix(1).uppercased() + name.dropFirst()) would high-five you if they had thumbs.",
            "All tasks complete. My food bowl is full and I've decided to ignore you anyway.",
            "You have satisfied my needs. My demands may change without notice.",
            "Tasks done. I have eaten, been walked, and judged you silently. All is well.",
            "All care protocols have been executed successfully. Stand by for tomorrow's mission.",
            "The board has reviewed today's pet care report. Results: exceptional.",
            "TASKS: DEMOLISHED. PET: THRIVING. YOU: A LEGEND.",
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return EmptyStateView(
            systemImage: "pawprint.fill",
            title: "All done!",
            message: messages[dayOfYear % messages.count]
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
