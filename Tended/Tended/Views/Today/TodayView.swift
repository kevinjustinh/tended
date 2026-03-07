import SwiftUI
import SwiftData

private enum TodayFilter: String, CaseIterable {
    case all = "All"
    case upcoming = "Upcoming"
    case overdue = "Overdue"
    case completed = "Done"
}

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @Query(sort: \TendedTask.dueTimeSeconds) private var allTasks: [TendedTask]

    @State private var viewModel = TodayViewModel()
    @State private var taskVM = TaskViewModel()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var filter: TodayFilter = .all

    private var displayedTasks: [TendedTask] {
        viewModel.tasksForDate(selectedDate, from: allTasks, petID: viewModel.selectedPetID)
    }

    private var filteredTasks: [TendedTask] {
        switch filter {
        case .all:       return displayedTasks
        case .upcoming:  return displayedTasks.filter { !$0.isCompleted && !$0.isOverdue }
        case .completed: return displayedTasks.filter(\.isCompleted)
        case .overdue:   return displayedTasks.filter { $0.isOverdue && !$0.isCompleted }
        }
    }

    private var grouped: [(TaskCategory, [TendedTask])] {
        viewModel.tasksByCategory(from: filteredTasks)
    }

    private var upcomingChronological: [TendedTask] {
        filteredTasks.sorted { ($0.dueTimeSeconds ?? Int.max) < ($1.dueTimeSeconds ?? Int.max) }
    }

    private var progress: Double {
        viewModel.completionProgress(from: displayedTasks)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var selectedPetName: String? {
        guard let id = viewModel.selectedPetID else { return nil }
        return pets.first(where: { $0.id == id })?.name
    }

    private var dateLabel: String {
        if isToday { return "Today" }
        if Calendar.current.isDateInTomorrow(selectedDate) { return "Tomorrow" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: selectedDate)
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

                        // Filter bar
                        filterBar

                        // Task groups
                        if filter == .upcoming {
                            if upcomingChronological.isEmpty {
                                EmptyStateView.allDone(petName: selectedPetName)
                                    .frame(minHeight: 280)
                            } else {
                                ChronologicalTaskList(
                                    tasks: upcomingChronological,
                                    onToggle: { task in
                                        viewModel.toggleCompletion(task, in: context, allTasks: allTasks)
                                        viewModel.didFinishToggle(displayedTasks: displayedTasks)
                                    },
                                    onDelete: { task in
                                        viewModel.delete(task, in: context)
                                    },
                                    isFuturePreview: !isToday
                                )
                                .padding(.horizontal, Spacing.lg)
                            }
                        } else if grouped.isEmpty {
                            EmptyStateView.allDone(petName: selectedPetName)
                                .frame(minHeight: 280)
                        } else {
                            ForEach(grouped, id: \.0) { category, tasks in
                                CategoryGroupCard(
                                    category: category,
                                    tasks: tasks,
                                    onToggle: { task in
                                        viewModel.toggleCompletion(task, in: context, allTasks: allTasks)
                                        viewModel.didFinishToggle(displayedTasks: displayedTasks)
                                    },
                                    onDelete: { task in
                                        viewModel.delete(task, in: context)
                                    },
                                    isFuturePreview: !isToday
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

                // Undo banner (sits above FAB)
                VStack(spacing: 0) {
                    Spacer()
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
                        .padding(.bottom, Spacing.xl + 56 + Spacing.sm)
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $taskVM.showSheet) {
            AddTaskSheet(taskVM: taskVM, pets: pets)
        }
        .onAppear {
            viewModel.generateTodayOccurrences(from: allTasks, in: context)
            viewModel.checkBirthdays(pets: pets)
        }
        .onChange(of: selectedDate) {
            filter = .all
            viewModel.allDoneMessage = nil
        }
        .onChange(of: allTasks) {
            viewModel.checkAllDone(tasks: displayedTasks)
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
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(TodayFilter.allCases, id: \.self) { f in
                    Button { withAnimation(.springPop) { filter = f } } label: {
                        Text(f.rawValue)
                            .font(.cardTitle(size: 13))
                            .foregroundStyle(filter == f ? .white : Color.textPrimary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(filter == f ? Color.sageGreen : Color.softLinen, in: Capsule())
                            .overlay(Capsule().stroke(filter == f ? Color.clear : Color.warmSand, lineWidth: 1))
                    }
                    .animation(.springPop, value: filter)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            mainHeader

            // Birthday banner
            if isToday && !viewModel.birthdayPets.isEmpty {
                let names = viewModel.birthdayPets.map(\.name).joined(separator: " & ")
                HStack(spacing: Spacing.sm) {
                    Text("🎂")
                        .font(.title3)
                    Text("Happy birthday, \(names)!")
                        .font(.cardTitle(size: 14))
                        .foregroundStyle(Color.deepForest)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.warmTan.opacity(0.25), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                .padding(.horizontal, Spacing.lg)
                .transition(.scale.combined(with: .opacity))
            }

            // All-done message (All filter only)
            if filter == .all, let message = viewModel.allDoneMessage {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "star.fill")
                        .font(.caption())
                        .foregroundStyle(Color.warmTan)
                    Text(message)
                        .font(.cardTitle(size: 14))
                        .foregroundStyle(Color.deepForest)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.successMoss.opacity(0.15), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                .padding(.horizontal, Spacing.lg)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var mainHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(isToday ? viewModel.greeting + "!" : dateLabel)
                    .font(.displayTitle(size: 26))
                    .foregroundStyle(Color.deepForest)

                let petName: String = {
                    if let id = viewModel.selectedPetID {
                        return pets.first(where: { $0.id == id })?.name ?? "your pet"
                    }
                    switch pets.count {
                    case 0: return "your pets"
                    case 1: return pets[0].name
                    case 2: return "\(pets[0].name) and \(pets[1].name)"
                    default:
                        let allButLast = pets.dropLast().map(\.name).joined(separator: ", ")
                        return "\(allButLast), and \(pets.last!.name)"
                    }
                }()
                let dayWord = isToday ? "today" : dateLabel
                Text("Here's what \(petName) need\(viewModel.selectedPetID == nil && pets.count > 1 ? "" : "s") \(dayWord).")
                    .font(.bodyText())
                    .foregroundStyle(Color.textSecondary)

                // Date navigation
                HStack(spacing: Spacing.sm) {
                    Button {
                        withAnimation(.springPop) {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.sageGreen)
                            .frame(width: 28, height: 28)
                    }

                    Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.caption())
                        .foregroundStyle(Color.textSecondary)

                    Button {
                        withAnimation(.springPop) {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.sageGreen)
                            .frame(width: 28, height: 28)
                    }

                    if !isToday {
                        Button {
                            withAnimation(.springPop) {
                                selectedDate = Calendar.current.startOfDay(for: Date())
                            }
                        } label: {
                            Text("Today")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.sageGreen, in: Capsule())
                        }
                    }
                }
            }

            Spacer()

            ProgressRingView(progress: progress)
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
    var isFuturePreview: Bool = false

    var completedCount: Int { isFuturePreview ? 0 : tasks.filter(\.isCompleted).count }

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
                    InteractiveTaskRow(
                        task: task,
                        onToggle: { onToggle(task) },
                        onDelete: { onDelete(task) },
                        isFuturePreview: isFuturePreview
                    )

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

// MARK: - Chronological task list (Upcoming filter)

private struct ChronologicalTaskList: View {
    let tasks: [TendedTask]
    let onToggle: (TendedTask) -> Void
    let onDelete: (TendedTask) -> Void
    var isFuturePreview: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ForEach(tasks) { task in
                InteractiveTaskRow(
                    task: task,
                    onToggle: { onToggle(task) },
                    onDelete: { onDelete(task) },
                    isFuturePreview: isFuturePreview
                )

                if task.id != tasks.last?.id {
                    Divider()
                        .padding(.leading, 60)
                        .background(Color.warmSand)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .shadow(color: Color.deepForest.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Interactive task row (checkbox left, nav right)

private struct InteractiveTaskRow: View {
    let task: TendedTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    var isFuturePreview: Bool = false

    @State private var checkScale: CGFloat = 1.0

    private var showCompleted: Bool { !isFuturePreview && task.isCompleted }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checkbox — tap to complete
            Button {
                guard !isFuturePreview else { return }
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
                        Circle().fill(Color.successMoss).frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(checkScale)
                .frame(width: 44)
                .frame(maxHeight: .infinity)             }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .opacity(isFuturePreview ? 0.4 : 1.0)

            // Right side — tap to navigate to detail
            NavigationLink(destination: TaskDetailView(task: task)) {
                HStack(spacing: Spacing.md) {
                    CategoryIconView(category: task.category, size: 30)

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

                    if task.isOverdue && !showCompleted && !isFuturePreview {
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
                .padding(.vertical, Spacing.md)
                .padding(.trailing, Spacing.lg)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, Spacing.lg)
        .background(Color.softLinen)
        .opacity(showCompleted ? 0.65 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: showCompleted)
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(PersistenceController.preview)
}
