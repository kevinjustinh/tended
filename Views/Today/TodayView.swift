import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @Query(sort: \TendedTask.dueTimeSeconds) private var allTasks: [TendedTask]

    @State private var viewModel = TodayViewModel()
    @State private var taskVM = TaskViewModel()

    private var todayTasks: [TendedTask] {
        viewModel.filteredTasks(from: allTasks, petID: viewModel.selectedPetID)
    }

    private var grouped: [(TaskCategory, [TendedTask])] {
        viewModel.tasksByCategory(from: todayTasks)
    }

    private var progress: Double {
        viewModel.completionProgress(from: todayTasks)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.creamWhite.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: Spacing.lg, pinnedViews: .sectionHeaders) {
                        // Header
                        headerSection

                        // Pet selector
                        if !pets.isEmpty {
                            PetSelectorView(pets: pets, selectedPetID: $viewModel.selectedPetID)
                        }

                        // Task groups
                        if grouped.isEmpty {
                            EmptyStateView.allDone()
                                .frame(minHeight: 280)
                        } else {
                            ForEach(grouped, id: \.0) { category, tasks in
                                CategoryGroupCard(
                                    category: category,
                                    tasks: tasks,
                                    onToggle: { task in
                                        viewModel.toggleCompletion(task, in: context, allTasks: allTasks)
                                    },
                                    onDelete: { task in
                                        viewModel.delete(task, in: context)
                                    },
                                    onEdit: { task in
                                        taskVM.openEditSheet(task: task)
                                    }
                                )
                                .padding(.horizontal, Spacing.lg)
                            }
                        }

                        Spacer(minLength: 80)
                    }
                }
                .refreshable {
                    viewModel.generateTodayOccurrences(from: allTasks, in: context)
                }

                // Undo banner + FAB stack
                VStack(spacing: 0) {
                    Spacer()

                    // Undo banner
                    if viewModel.showUndoBanner, let task = viewModel.lastCompletedTask {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.successMoss)
                            Text("\"\(task.title)\" marked done")
                                .font(.bodyText())
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Button("Undo") {
                                viewModel.undoCompletion(in: context)
                            }
                            .font(.cardTitle(size: 14))
                            .foregroundStyle(Color.sageGreen)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(Color.softLinen)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                        .shadow(color: Color.textPrimary.opacity(0.12), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.sm)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // FAB
                Button {
                    taskVM.openAddSheet()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.sageGreen, in: Circle())
                        .shadow(color: Color.deepForest.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .padding([.trailing, .bottom], Spacing.xl)

                ConfettiView(isVisible: viewModel.showConfetti)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Today")
                        .font(.displayTitle(size: 28))
                        .foregroundStyle(Color.deepForest)
                }
            }
        }
        .sheet(isPresented: $taskVM.showSheet) {
            AddTaskSheet(taskVM: taskVM, pets: pets)
        }
        .onAppear {
            viewModel.generateTodayOccurrences(from: allTasks, in: context)
            viewModel.checkBirthdays(pets: pets)
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskMarkedDoneFromNotification)) { note in
            guard let uuid = note.object as? UUID,
                  let task = allTasks.first(where: { $0.id == uuid }) else { return }
            viewModel.complete(task, in: context)
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskSnoozedFromNotification)) { note in
            guard let uuid = note.object as? UUID,
                  let task = allTasks.first(where: { $0.id == uuid }) else { return }
            // Reschedule 1hr later
            if let time = task.dueTime {
                task.dueTime = time.addingTimeInterval(3600)
                NotificationService.shared.cancelReminder(for: task)
                NotificationService.shared.scheduleReminder(for: task)
                try? context.save()
            }
        }
        // Regenerate today's tasks when DST changes, at midnight, or when the
        // user manually adjusts the system clock. This ensures task times and
        // recurring occurrences always reflect the phone's current timezone.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            viewModel.generateTodayOccurrences(from: allTasks, in: context)
            viewModel.rescheduleAllNotifications(from: allTasks)
        }
        // Also regenerate when the app returns to the foreground — catches the
        // case where DST or a day change happened while the app was backgrounded.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.generateTodayOccurrences(from: allTasks, in: context)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(viewModel.greeting + "!")
                        .font(.displayTitle(size: 26))
                        .foregroundStyle(Color.deepForest)

                    let petName: String = {
                        if let id = viewModel.selectedPetID {
                            return pets.first(where: { $0.id == id })?.name ?? "your pet"
                        }
                        return pets.first?.name ?? "your pets"
                    }()
                    Text("Here's what \(petName) needs today.")
                        .font(.bodyText())
                        .foregroundStyle(Color.textSecondary)

                    // Date
                    Text(Date(), format: .dateTime.weekday(.wide).month().day())
                        .font(.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                ProgressRingView(progress: progress)
            }

            // Birthday banner
            if !viewModel.birthdayPets.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Text("🎂")
                        .font(.title3)
                    let names = viewModel.birthdayPets.map(\.name).joined(separator: " & ")
                    Text("Happy birthday, \(names)!")
                        .font(.cardTitle(size: 14))
                        .foregroundStyle(Color.deepForest)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.warmTan.opacity(0.25), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}

// MARK: - Category group card

private struct CategoryGroupCard: View {
    let category: TaskCategory
    let tasks: [TendedTask]
    let onToggle: (TendedTask) -> Void
    let onDelete: (TendedTask) -> Void
    let onEdit: (TendedTask) -> Void

    var completedCount: Int { tasks.filter(\.isCompleted).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack {
                CategoryIconView(category: category, size: 28)
                Text(category.displayName)
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(completedCount)/\(tasks.count)")
                    .font(.monoText())
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(category.cardColor.opacity(0.6))

            Divider().background(Color.warmSand)

            // Task rows
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TaskCardView(task: task, onToggle: { onToggle(task) })
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { onDelete(task) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button { onEdit(task) } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Color.warmTan)
                        }
                        .contextMenu {
                            Button { onEdit(task) } label: {
                                Label("Edit Task", systemImage: "pencil")
                            }
                            Button(role: .destructive) { onDelete(task) } label: {
                                Label("Delete Task", systemImage: "trash")
                            }
                        }

                    if task.id != tasks.last?.id {
                        Divider()
                            .padding(.leading, 60)
                            .background(Color.warmSand)
                    }
                }
            }
        }
        .cardStyle(color: .softLinen)
    }
}

#Preview {
    TodayView()
        .modelContainer(PersistenceController.preview)
}
