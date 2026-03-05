import SwiftUI

struct TaskCardView: View {
    let task: TendedTask
    let onToggle: () -> Void

    @State private var checkScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Completion toggle
            Button {
                withAnimation(.springPop) { checkScale = 1.3 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.springPop) { checkScale = 1.0 }
                }
                onToggle()
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.successMoss : Color.warmSand, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if task.isCompleted {
                        Circle()
                            .fill(Color.successMoss)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(checkScale)
            }
            .buttonStyle(.plain)

            // Category icon
            CategoryIconView(category: task.category, size: 30)

            // Task title + pet name
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.cardTitle(size: 15))
                    .foregroundStyle(task.isCompleted ? Color.textSecondary : Color.textPrimary)
                    .strikethrough(task.isCompleted, color: Color.textSecondary)

                if let petName = task.pet?.name {
                    Text(petName)
                        .font(.caption())
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            // Time or overdue indicator
            if task.isOverdue && !task.isCompleted {
                Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption())
                    .foregroundStyle(Color.alertAmber)
                    .labelStyle(.iconOnly)
            } else if !task.formattedDueTime.isEmpty {
                Text(task.formattedDueTime)
                    .font(.monoText())
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.softLinen)
        .opacity(task.isCompleted ? 0.65 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
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
