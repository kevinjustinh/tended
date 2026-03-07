import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: TendedTask

    @State private var taskVM = TaskViewModel()
    @State private var showDeleteConfirm = false
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    var body: some View {
        ZStack {
            Color.creamWhite.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Category header
                    HStack(spacing: Spacing.md) {
                        CategoryIconView(category: task.category, size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.displayTitle(size: 24))
                                .foregroundStyle(Color.textPrimary)
                            if let petName = task.pet?.name {
                                Text(petName)
                                    .font(.bodyText())
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    // Notes (shown first when present)
                    if !task.notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Notes")
                                .font(.cardTitle())
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal, Spacing.lg)
                            Text(task.notes)
                                .font(.bodyText())
                                .foregroundStyle(Color.textPrimary)
                                .padding(Spacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cardStyle()
                                .padding(.horizontal, Spacing.lg)
                        }
                    }

                    // Details card
                    VStack(spacing: 0) {
                        DetailRow(label: "Category", value: task.category.displayName)
                        Divider().padding(.leading, Spacing.lg)
                        DetailRow(label: "Due", value: task.dueDate.map { $0.formatted(.dateTime.weekday().month().day()) } ?? "—")
                        if !task.formattedDueTime.isEmpty {
                            Divider().padding(.leading, Spacing.lg)
                            DetailRow(label: "Time", value: task.formattedDueTime)
                        }
                        if task.isRecurring, let rule = task.recurrenceRule {
                            Divider().padding(.leading, Spacing.lg)
                            DetailRow(label: "Repeats", value: rule.displayString)
                        }
                        if task.notificationEnabled {
                            Divider().padding(.leading, Spacing.lg)
                            DetailRow(label: "Notifications", value: "On")
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal, Spacing.lg)

                    // Completion status
                    VStack(spacing: 0) {
                        DetailRow(
                            label: "Status",
                            value: task.isCompleted
                                ? "Done \(task.completedAt.map { $0.formatted(.dateTime.hour().minute()) } ?? "")"
                                : (task.isOverdue ? "Overdue" : "Pending")
                        )
                    }
                    .cardStyle()
                    .padding(.horizontal, Spacing.lg)

                    // Delete button
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                            .font(.cardTitle())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                            .background(Color.alertAmber, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                            .padding(.horizontal, Spacing.xl)
                    }
                }
                .padding(.vertical, Spacing.lg)
            }
        }
        .navigationTitle("Task Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { taskVM.openEditSheet(task: task) }
            }
        }
        .sheet(isPresented: $taskVM.showSheet) {
            AddTaskSheet(taskVM: taskVM, pets: pets)
        }
        .confirmationDialog("Delete \"\(task.title)\"?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                taskVM.deleteTask(task, in: context)
                dismiss()
            }
        } message: {
            Text("This task will be permanently deleted.")
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyText())
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.cardTitle(size: 15))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
}
