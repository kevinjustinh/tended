import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TendedTask.dueTimeSeconds) private var allTasks: [TendedTask]
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    @State private var taskVM = TaskViewModel()

    private var grouped: [(TaskCategory, [TendedTask])] {
        taskVM.tasksByCategory(taskVM.filteredTasks(allTasks))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.creamWhite.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter bar
                    filterBar

                    if grouped.isEmpty {
                        EmptyStateView.noTasks { taskVM.openAddSheet(category: taskVM.filterCategory ?? .feeding) }
                    } else {
                        List {
                            ForEach(grouped, id: \.0) { category, tasks in
                                Section {
                                    ForEach(tasks) { task in
                                        NavigationLink {
                                            TaskDetailView(task: task)
                                        } label: {
                                            TaskRowView(task: task)
                                        }
                                        .listRowBackground(Color.softLinen)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                taskVM.deleteTask(task, in: context)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button { taskVM.openEditSheet(task: task) } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(Color.warmTan)
                                        }
                                    }
                                } header: {
                                    HStack(spacing: Spacing.sm) {
                                        CategoryIconView(category: category, size: 20)
                                        Text(category.displayName)
                                            .font(.cardTitle(size: 13))
                                            .foregroundStyle(Color.textSecondary)
                                        Spacer()
                                        Text("\(tasks.count)")
                                            .font(.monoText())
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    .textCase(nil)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { taskVM.openAddSheet() } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.sageGreen, in: Circle())
                                .shadow(color: Color.deepForest.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .padding([.trailing, .bottom], Spacing.xl)
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $taskVM.showSheet) {
            AddTaskSheet(taskVM: taskVM, pets: pets)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // All categories
                FilterChip(
                    label: "All",
                    isSelected: taskVM.filterCategory == nil,
                    action: { taskVM.filterCategory = nil }
                )

                ForEach(TaskCategory.allCases) { cat in
                    FilterChip(
                        label: cat.displayName,
                        isSelected: taskVM.filterCategory == cat,
                        action: { taskVM.filterCategory = taskVM.filterCategory == cat ? nil : cat }
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
    }
}

private struct TaskRowView: View {
    let task: TendedTask

    var body: some View {
        HStack(spacing: Spacing.md) {
            CategoryIconView(category: task.category, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.cardTitle(size: 15))
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: Spacing.xs) {
                    if let petName = task.pet?.name {
                        Text(petName)
                            .font(.caption())
                            .foregroundStyle(Color.textSecondary)
                    }
                    if task.isRecurring {
                        Text("·")
                            .foregroundStyle(Color.textSecondary)
                        Text(task.recurrenceRule?.displayString ?? "Recurring")
                            .font(.caption())
                            .foregroundStyle(Color.sageGreen)
                    }
                }
            }
            Spacer()
            if !task.formattedDueTime.isEmpty {
                Text(task.formattedDueTime)
                    .font(.monoText())
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.cardTitle(size: 13))
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.sageGreen : Color.softLinen, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color.warmSand, lineWidth: 1))
        }
        .animation(.springPop, value: isSelected)
    }
}

#Preview {
    TaskListView()
        .modelContainer(PersistenceController.preview)
}
