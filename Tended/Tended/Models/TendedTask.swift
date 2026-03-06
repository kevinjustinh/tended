import Foundation
import SwiftData

@Model
final class TendedTask {
    var id: UUID
    var title: String
    var categoryRaw: String
    var pet: Pet?
    var dueDate: Date?
    /// Hour/minute stored as seconds since midnight for convenience
    var dueTimeSeconds: Int?
    var isRecurring: Bool
    /// JSON-encoded RecurrenceRule
    var recurrenceRuleData: Data?
    var notes: String
    var isCompleted: Bool
    var completedAt: Date?
    var notificationEnabled: Bool
    /// Used to group recurring instances — equals the root task id
    var recurrenceGroupID: UUID?
    /// The original start date (anchor) for recurring tasks
    var recurrenceStartDate: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory = .custom,
        pet: Pet? = nil,
        dueDate: Date? = nil,
        dueTimeSeconds: Int? = nil,
        isRecurring: Bool = false,
        recurrenceRule: RecurrenceRule? = nil,
        notes: String = "",
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        notificationEnabled: Bool = true,
        recurrenceGroupID: UUID? = nil,
        recurrenceStartDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.pet = pet
        self.dueDate = dueDate
        self.dueTimeSeconds = dueTimeSeconds
        self.isRecurring = isRecurring
        self.recurrenceRuleData = recurrenceRule.flatMap { try? JSONEncoder().encode($0) }
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notificationEnabled = notificationEnabled
        self.recurrenceGroupID = recurrenceGroupID
        self.recurrenceStartDate = recurrenceStartDate
        self.createdAt = createdAt
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var recurrenceRule: RecurrenceRule? {
        get {
            guard let data = recurrenceRuleData else { return nil }
            return try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        set {
            recurrenceRuleData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }

    var dueTime: Date? {
        get {
            guard let secs = dueTimeSeconds, let base = dueDate else { return nil }
            let cal = Calendar.current
            let startOfDay = cal.startOfDay(for: base)
            return cal.date(byAdding: .second, value: secs, to: startOfDay)
        }
        set {
            if let t = newValue {
                let cal = Calendar.current
                let comps = cal.dateComponents([.hour, .minute, .second], from: t)
                dueTimeSeconds = (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60 + (comps.second ?? 0)
            } else {
                dueTimeSeconds = nil
            }
        }
    }

    var formattedDueTime: String {
        guard let t = dueTime else { return "" }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return fmt.string(from: t)
    }

    var isOverdue: Bool {
        guard !isCompleted, let t = dueTime else { return false }
        return t < Date()
    }
}

// MARK: - Template definitions

extension TendedTask {
    static func morningFeedTemplate(for pet: Pet) -> TendedTask {
        let task = TendedTask(
            title: "Morning Feed",
            category: .feeding,
            pet: pet,
            dueDate: Calendar.current.startOfDay(for: Date()),
            dueTimeSeconds: 7 * 3600,
            isRecurring: true,
            recurrenceRule: .daily,
            notificationEnabled: true,
            recurrenceStartDate: Date()
        )
        task.recurrenceGroupID = task.id
        return task
    }

    static func eveningFeedTemplate(for pet: Pet) -> TendedTask {
        let task = TendedTask(
            title: "Evening Feed",
            category: .feeding,
            pet: pet,
            dueDate: Calendar.current.startOfDay(for: Date()),
            dueTimeSeconds: 18 * 3600,
            isRecurring: true,
            recurrenceRule: .daily,
            notificationEnabled: true,
            recurrenceStartDate: Date()
        )
        task.recurrenceGroupID = task.id
        return task
    }

    static func morningWalkTemplate(for pet: Pet) -> TendedTask {
        let task = TendedTask(
            title: "Morning Walk",
            category: .exercise,
            pet: pet,
            dueDate: Calendar.current.startOfDay(for: Date()),
            dueTimeSeconds: 8 * 3600,
            isRecurring: true,
            recurrenceRule: .daily,
            notificationEnabled: true,
            recurrenceStartDate: Date()
        )
        task.recurrenceGroupID = task.id
        return task
    }

    static func eveningWalkTemplate(for pet: Pet) -> TendedTask {
        let task = TendedTask(
            title: "Evening Walk",
            category: .exercise,
            pet: pet,
            dueDate: Calendar.current.startOfDay(for: Date()),
            dueTimeSeconds: 18 * 3600 + 1800,
            isRecurring: true,
            recurrenceRule: .daily,
            notificationEnabled: true,
            recurrenceStartDate: Date()
        )
        task.recurrenceGroupID = task.id
        return task
    }

    static func freshWaterTemplate(for pet: Pet) -> TendedTask {
        let task = TendedTask(
            title: "Fresh Water",
            category: .water,
            pet: pet,
            dueDate: Calendar.current.startOfDay(for: Date()),
            dueTimeSeconds: 8 * 3600,
            isRecurring: true,
            recurrenceRule: .daily,
            notificationEnabled: false,
            recurrenceStartDate: Date()
        )
        task.recurrenceGroupID = task.id
        return task
    }
}
