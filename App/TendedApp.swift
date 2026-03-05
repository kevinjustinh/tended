import SwiftUI
import SwiftData

@main
struct TendedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(PersistenceController.shared.container)
    }
}

// MARK: - App Delegate (notification delegate setup)

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register NotificationService as UNUserNotificationCenter delegate.
        // The singleton init also calls center.delegate = self and registers categories.
        _ = NotificationService.shared
        return true
    }
}
