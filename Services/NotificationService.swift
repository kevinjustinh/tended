import UserNotifications
import Foundation

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    // Notification category & action identifiers
    static let categoryID   = "TASK_REMINDER"
    static let actionDone   = "MARK_DONE"
    static let actionSnooze = "SNOOZE"

    private override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }

    // MARK: - Permission

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    func scheduleReminder(for task: TendedTask) {
        guard task.notificationEnabled, let fireDate = task.dueTime else { return }

        let content = UNMutableNotificationContent()
        content.title = task.pet?.name ?? "Tended"
        content.body  = task.title
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["taskID": task.id.uuidString]

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)

        center.add(request) { _ in }
    }

    func cancelReminder(for task: TendedTask) {
        center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Overdue alert

    func scheduleOverdueAlert(for task: TendedTask, after delay: TimeInterval = 3600) {
        guard task.notificationEnabled, let dueTime = task.dueTime, !task.isCompleted else { return }
        let fireDate = dueTime.addingTimeInterval(delay)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Overdue: \(task.title)"
        content.body  = "\(task.pet?.name ?? "Your pet") is waiting!"
        content.sound = .defaultCritical
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["taskID": task.id.uuidString]

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = "overdue-\(task.id.uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    // MARK: - Weekly summary

    func scheduleWeeklySummary(for petName: String, petID: UUID) {
        var comps = DateComponents()
        comps.weekday = 1   // Sunday
        comps.hour = 9
        comps.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Tended Weekly"
        content.body  = "Here's how \(petName)'s week went \u{1F43E}"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-\(petID.uuidString)", content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse) async {
        let taskIDString = response.notification.request.content.userInfo["taskID"] as? String
        switch response.actionIdentifier {
        case Self.actionDone:
            if let idStr = taskIDString, let uuid = UUID(uuidString: idStr) {
                await markTaskDoneFromNotification(taskID: uuid)
            }
        case Self.actionSnooze:
            if let idStr = taskIDString, let uuid = UUID(uuidString: idStr) {
                await snoozeTaskFromNotification(taskID: uuid)
            }
        default:
            break
        }
    }

    // MARK: - Private

    private func registerCategories() {
        let doneAction = UNNotificationAction(
            identifier: Self.actionDone,
            title: "Mark Done",
            options: [.authenticationRequired]
        )
        let snoozeAction = UNNotificationAction(
            identifier: Self.actionSnooze,
            title: "Snooze 1 hr",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [doneAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    @MainActor
    private func markTaskDoneFromNotification(taskID: UUID) {
        // TodayViewModel handles completion; post a notification for it to observe
        NotificationCenter.default.post(name: .taskMarkedDoneFromNotification, object: taskID)
    }

    @MainActor
    private func snoozeTaskFromNotification(taskID: UUID) {
        NotificationCenter.default.post(name: .taskSnoozedFromNotification, object: taskID)
    }
}

extension Notification.Name {
    static let taskMarkedDoneFromNotification = Notification.Name("taskMarkedDoneFromNotification")
    static let taskSnoozedFromNotification    = Notification.Name("taskSnoozedFromNotification")
}
