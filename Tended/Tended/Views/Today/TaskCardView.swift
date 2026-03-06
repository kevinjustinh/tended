import SwiftUI

struct TaskCardView: View {
    let task: TendedTask
    let onToggle: () -> Void
    var isInteractive: Bool = true

    @State private var checkScale: CGFloat = 1.0

    private var showCompleted: Bool { isInteractive && task.isCompleted }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Completion toggle
            Button {
                guard isInteractive else { return }
                withAnimation(.springPop) { checkScale = 1.3 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.springPop) { checkScale = 1.0 }
                }
                onToggle()
            } label: {
                ZStack {
                    Circle()
                        .stroke(showCompleted ? Color.successMoss : Color.warmSand, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if showCompleted {
                        Circle()
                            .fill(Color.successMoss)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(checkScale)
                .frame(width: 44)
                .frame(maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .opacity(isInteractive ? 1.0 : 0.4)

            // Category icon
            CategoryIconView(category: task.category, size: 30)

            // Task title + pet name
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.cardTitle(size: 15))
                    .foregroundStyle(showCompleted ? Color.textSecondary : Color.textPrimary)
                    .strikethrough(showCompleted, color: Color.textSecondary)

                if let petName = task.pet?.name {
                    Text(petName)
                        .font(.caption())
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            // Time or overdue indicator
            if task.isOverdue && !showCompleted && isInteractive {
                HStack(spacing: 4) {
                    if !task.formattedDueTime.isEmpty {
                        Text(task.formattedDueTime)
                            .font(.monoText())
                            .foregroundStyle(Color.alertAmber)
                    }
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption())
                        .foregroundStyle(Color.alertAmber)
                }
            } else if !task.formattedDueTime.isEmpty {
                Text(task.formattedDueTime)
                    .font(.monoText())
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.softLinen)
        .opacity(showCompleted ? 0.65 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: showCompleted)
    }
}

#Preview {
    let pet = Pet(name: "Luna", species: .dog)
    let task = TendedTask(title: "Morning Feed", category: .feeding, pet: pet,
                          dueDate: Date(), dueTimeSeconds: 7 * 3600)
    return VStack(spacing: 1) {
        TaskCardView(task: task, onToggle: {})
        TaskCardView(task: TendedTask(title: "Flea Med", category: .medication, pet: pet,
                                     isCompleted: true), onToggle: {})
    }
    .background(Color.creamWhite)
}
