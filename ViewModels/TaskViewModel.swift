import SwiftUI
import SwiftData

@Observable
final class TaskViewModel {
    // Add/edit task sheet state
    var editingTask: TendedTask?
    var showSheet: Bool = false

    // Form fields (used for both add and edit)
    var formTitle: String = ""
    var formCategory: TaskCategory = .feeding
    var formPet: Pet?
    var formDueDate: Date = Date()
    var formDueTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var formHasTime: Bool = false
    var formIsRecurring: Bool = false
    var formFrequency: RecurrenceFrequency = .daily
    var formInterval: Int = 1
    var formWeekdays: Set<Int> = []
    var formNotes: String = ""
    var formNotificationEnabled: Bool = true
    var filterCategory: TaskCategory?
    var filterPetID: UUID?

    // MARK: - Sheet management

    func openAddSheet(pet: Pet? = nil, category: TaskCategory = .feeding) {
        editingTask = nil
        resetForm()
        formPet = pet
        formCategory = category
        showSheet = true
    }

    func openEditSheet(task: TendedTask) {
        editingTask = task
        formTitle = task.title
        formCategory = task.category
        formPet = task.pet
        formDueDate = task.dueDate ?? Date()
        if let t = task.dueTime {
            formDueTime = t
            formHasTime = true
        } else {
            formHasTime = false
        }
        formIsRecurring = task.isRecurring
        if let rule = task.recurrenceRule {
            formFrequency = rule.frequency
            formInterval = rule.interval
            formWeekdays = Set(rule.weekdays)
        }
        formNotes = task.notes
        formNotificationEnabled = task.notificationEnabled
        showSheet = true
    }

    // MARK: - Save

    func saveTask(in context: ModelContext) {
        if let existing = editingTask {
            applyForm(to: existing)
            NotificationService.shared.cancelReminder(for: existing)
            NotificationService.shared.scheduleReminder(for: existing)
        } else {
            let task = TendedTask()
            applyForm(to: task)
            if task.isRecurring {
                task.recurrenceGroupID = task.id
                task.recurrenceStartDate = task.dueDate
            }
            context.insert(task)
            NotificationService.shared.scheduleReminder(for: task)
        }
        try? context.save()
        showSheet = false
    }

    func deleteTask(_ task: TendedTask, in context: ModelContext) {
        HapticStyle.delete.trigger()
        NotificationService.shared.cancelReminder(for: task)
        context.delete(task)
        try? context.save()
    }

    // MARK: - Filtering

    func filteredTasks(_ tasks: [TendedTask]) -> [TendedTask] {
        tasks.filter { task in
            if let cat = filterCategory, task.category != cat { return false }
            if let petID = filterPetID, task.pet?.id != petID { return false }
            return true
        }
    }

    func tasksByCategory(_ tasks: [TendedTask]) -> [(TaskCategory, [TendedTask])] {
        var grouped: [TaskCategory: [TendedTask]] = [:]
        for task in tasks {
            grouped[task.category, default: []].append(task)
        }
        return TaskCategory.allCases.compactMap { cat in
            guard let list = grouped[cat], !list.isEmpty else { return nil }
            return (cat, list.sorted { $0.createdAt < $1.createdAt })
        }
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !formTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Private

    private func applyForm(to task: TendedTask) {
        task.title = formTitle.trimmingCharacters(in: .whitespaces)
        task.category = formCategory
        task.pet = formPet
        task.dueDate = Calendar.current.startOfDay(for: formDueDate)
        if formHasTime {
            task.dueTime = formDueTime
        } else {
            task.dueTimeSeconds = nil
        }
        task.isRecurring = formIsRecurring
        if formIsRecurring {
            let rule: RecurrenceRule
            switch formFrequency {
            case .daily:
                rule = .daily
            case .weekly:
                rule = formWeekdays.isEmpty ? .weekly : .weekdays(Array(formWeekdays).sorted())
            case .custom:
                rule = .every(formInterval)
            }
            task.recurrenceRule = rule
        } else {
            task.recurrenceRule = nil
        }
        task.notes = formNotes
        task.notificationEnabled = formNotificationEnabled
    }

    private func resetForm() {
        formTitle = ""
        formCategory = .feeding
        formPet = nil
        formDueDate = Date()
        formDueTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        formHasTime = false
        formIsRecurring = false
        formFrequency = .daily
        formInterval = 1
        formWeekdays = []
        formNotes = ""
        formNotificationEnabled = true
    }
}

// Allow creating a TendedTask with default init for form use
extension TendedTask {
    convenience init() {
        self.init(title: "", category: .custom)
    }
}
