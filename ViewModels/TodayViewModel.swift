import SwiftUI
import SwiftData
import Combine

@Observable
final class TodayViewModel {
    var selectedPetID: UUID?
    var showConfetti: Bool = false
    var showAddTask: Bool = false
    var showUndoBanner: Bool = false
    var lastCompletedTask: TendedTask?
    var birthdayPets: [Pet] = []

    private var cancellables = Set<AnyCancellable>()
    private var undoWorkItem: DispatchWorkItem?
    private var lastGeneratedDay: Date?

    init() {
        // Observe notification-action completions from the lock screen
        NotificationCenter.default
            .publisher(for: .taskMarkedDoneFromNotification)
            .sink { [weak self] note in
                guard let uuid = note.object as? UUID else { return }
                self?.handleNotificationComplete(taskID: uuid)
            }
            .store(in: &cancellables)
    }

    // MARK: - Today's tasks

    func todayTasks(from allTasks: [TendedTask]) -> [TendedTask] {
        let today = Calendar.current.startOfDay(for: Date())
        return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: today)
        }
    }

    func filteredTasks(from allTasks: [TendedTask], petID: UUID?) -> [TendedTask] {
        let today = todayTasks(from: allTasks)
        guard let petID else { return today }
        return today.filter { $0.pet?.id == petID }
    }

    func tasksByCategory(from tasks: [TendedTask]) -> [(TaskCategory, [TendedTask])] {
        var grouped: [TaskCategory: [TendedTask]] = [:]
        for task in tasks {
            grouped[task.category, default: []].append(task)
        }
        return TaskCategory.allCases
            .compactMap { cat -> (TaskCategory, [TendedTask])? in
                guard let tasks = grouped[cat], !tasks.isEmpty else { return nil }
                return (cat, tasks.sorted { ($0.dueTimeSeconds ?? 0) < ($1.dueTimeSeconds ?? 0) })
            }
    }

    func completionProgress(from tasks: [TendedTask]) -> Double {
        guard !tasks.isEmpty else { return 0 }
        let done = tasks.filter(\.isCompleted).count
        return Double(done) / Double(tasks.count)
    }

    // MARK: - Completion

    func complete(_ task: TendedTask, in context: ModelContext) {
        withAnimation(.springPop) {
            task.isCompleted = true
            task.completedAt = Date()
        }
        HapticStyle.taskComplete.trigger()
        NotificationService.shared.cancelReminder(for: task)
        // Defer the disk write so the animation frame renders first
        DispatchQueue.main.async { try? context.save() }

        lastCompletedTask = task
        withAnimation(.springCard) { showUndoBanner = true }
        undoWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            withAnimation(.springCard) { self?.showUndoBanner = false }
            self?.lastCompletedTask = nil
        }
        undoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
    }

    func undoCompletion(in context: ModelContext) {
        guard let task = lastCompletedTask else { return }
        undoWorkItem?.cancel()
        uncomplete(task, in: context)
        withAnimation(.springCard) { showUndoBanner = false }
        lastCompletedTask = nil
    }

    func uncomplete(_ task: TendedTask, in context: ModelContext) {
        withAnimation(.springPop) {
            task.isCompleted = false
            task.completedAt = nil
        }
        NotificationService.shared.scheduleReminder(for: task)
        DispatchQueue.main.async { try? context.save() }
    }

    func toggleCompletion(_ task: TendedTask, in context: ModelContext, allTasks: [TendedTask]) {
        if task.isCompleted {
            uncomplete(task, in: context)
        } else {
            complete(task, in: context)
            checkAllDone(allTasks: allTasks)
        }
    }

    // MARK: - Birthdays

    func checkBirthdays(pets: [Pet]) {
        let cal = Calendar.current
        let now = Date()
        let todayMonth = cal.component(.month, from: now)
        let todayDay = cal.component(.day, from: now)
        birthdayPets = pets.filter { pet in
            guard let dob = pet.dateOfBirth else { return false }
            return cal.component(.month, from: dob) == todayMonth &&
                   cal.component(.day, from: dob) == todayDay
        }
        if !birthdayPets.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { self.showConfetti = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { self.showConfetti = false }
                }
            }
        }
    }

    // MARK: - Recurrence generation

    /// Idempotently generates today's occurrence for each recurring task anchor.
    /// Skips work when called multiple times on the same calendar day (e.g. repeated foreground events).
    func generateTodayOccurrences(from allTasks: [TendedTask], in context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastGeneratedDay, Calendar.current.isDate(last, inSameDayAs: today) { return }
        lastGeneratedDay = today
        let existingTodayIDs = Set(allTasks.compactMap { task -> UUID? in
            guard let due = task.dueDate, Calendar.current.isDate(due, inSameDayAs: today) else { return nil }
            return task.recurrenceGroupID
        })

        for task in allTasks where task.isRecurring {
            guard let rule = task.recurrenceRule,
                  let start = task.recurrenceStartDate,
                  let groupID = task.recurrenceGroupID,
                  rule.fires(on: today, startingFrom: start),
                  !existingTodayIDs.contains(groupID) || task.dueDate.map({ Calendar.current.isDate($0, inSameDayAs: today) }) == true
            else { continue }

            // Only generate if no occurrence yet today for this group
            let alreadyExists = allTasks.contains { t in
                t.recurrenceGroupID == groupID &&
                t.dueDate.map({ Calendar.current.isDate($0, inSameDayAs: today) }) == true
            }
            guard !alreadyExists else { continue }

            let occurrence = TendedTask(
                title: task.title,
                category: task.category,
                pet: task.pet,
                dueDate: today,
                dueTimeSeconds: task.dueTimeSeconds,
                isRecurring: false,
                notes: task.notes,
                notificationEnabled: task.notificationEnabled,
                recurrenceGroupID: groupID
            )
            context.insert(occurrence)
            NotificationService.shared.scheduleReminder(for: occurrence)
        }
        try? context.save()
    }

    // MARK: - Notification rescheduling

    /// Cancel and re-schedule all pending reminders so their trigger times
    /// reflect the current timezone (important after DST transitions).
    func rescheduleAllNotifications(from allTasks: [TendedTask]) {
        for task in allTasks where !task.isCompleted && task.notificationEnabled && task.dueTime != nil {
            NotificationService.shared.cancelReminder(for: task)
            NotificationService.shared.scheduleReminder(for: task)
        }
    }

    // MARK: - Delete

    func delete(_ task: TendedTask, in context: ModelContext) {
        HapticStyle.delete.trigger()
        NotificationService.shared.cancelReminder(for: task)
        context.delete(task)
        try? context.save()
    }

    // MARK: - Greeting

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    // MARK: - Private

    private func checkAllDone(allTasks: [TendedTask]) {
        let today = todayTasks(from: allTasks)
        let allDone = !today.isEmpty && today.allSatisfy(\.isCompleted)
        if allDone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { self.showConfetti = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { self.showConfetti = false }
                }
            }
        }
    }

    private func handleNotificationComplete(taskID: UUID) {
        // Handled via SwiftData query in TodayView via .onReceive
    }
}
