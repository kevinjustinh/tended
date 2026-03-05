import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled")         private var notificationsEnabled = true
    @AppStorage("overdueDelayMinutes")          private var overdueDelayMinutes = 60
    @AppStorage("weeklySummaryEnabled")         private var weeklySummaryEnabled = true
    @AppStorage("reduceMotion")                 private var reduceMotion = false
    @AppStorage("hasOnboarded")                 private var hasOnboarded = true

    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.creamWhite.ignoresSafeArea()

                List {
                    // Notifications
                    Section {
                        Toggle("Enable notifications", isOn: $notificationsEnabled)
                            .tint(Color.sageGreen)
                            .onChange(of: notificationsEnabled) {
                                if notificationsEnabled {
                                    Task { _ = await NotificationService.shared.requestAuthorization() }
                                } else {
                                    NotificationService.shared.cancelAllReminders()
                                }
                            }

                        if notificationAuthStatus == .denied {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.alertAmber)
                                Text("Notifications blocked in Settings")
                                    .font(.caption())
                                    .foregroundStyle(Color.alertAmber)
                                Spacer()
                                Button("Open Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(.caption())
                                .foregroundStyle(Color.sageGreen)
                            }
                        }

                        Picker("Overdue alert after", selection: $overdueDelayMinutes) {
                            Text("30 minutes").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                        }
                        .tint(Color.sageGreen)
                        .disabled(!notificationsEnabled)

                        Toggle("Weekly summary", isOn: $weeklySummaryEnabled)
                            .tint(Color.sageGreen)
                            .disabled(!notificationsEnabled)
                    } header: {
                        sectionHeader("Notifications")
                    }
                    .listRowBackground(Color.softLinen)

                    // Accessibility
                    Section {
                        Toggle("Reduce motion", isOn: $reduceMotion)
                            .tint(Color.sageGreen)

                        NavigationLink {
                            AccessibilityInfoView()
                        } label: {
                            Label("Accessibility guide", systemImage: "accessibility")
                                .foregroundStyle(Color.textPrimary)
                        }
                    } header: {
                        sectionHeader("Accessibility")
                    }
                    .listRowBackground(Color.softLinen)

                    // About
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(Color.textSecondary)
                        }

                        Link(destination: URL(string: "https://apple.com/privacy")!) {
                            Label("Privacy Policy", systemImage: "lock.shield")
                                .foregroundStyle(Color.textPrimary)
                        }
                    } header: {
                        sectionHeader("About Tended")
                    }
                    .listRowBackground(Color.softLinen)

                    // Developer / debug
                    Section {
                        Button("Re-show Onboarding") {
                            hasOnboarded = false
                        }
                        .foregroundStyle(Color.sageGreen)

                        Button("Reset Notification Permissions", role: .destructive) {
                            showResetConfirm = true
                        }
                    } header: {
                        sectionHeader("Developer")
                    }
                    .listRowBackground(Color.softLinen)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationAuthStatus = settings.authorizationStatus
        }
        .confirmationDialog("Cancel all pending notifications?",
                            isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button("Cancel All", role: .destructive) {
                NotificationService.shared.cancelAllReminders()
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.cardTitle(size: 13))
            .foregroundStyle(Color.textSecondary)
            .textCase(nil)
    }
}

// MARK: - Accessibility info

private struct AccessibilityInfoView: View {
    var body: some View {
        ZStack {
            Color.creamWhite.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    accessibilityItem(
                        icon: "textformat.size",
                        title: "Dynamic Type",
                        detail: "All text scales with your preferred reading size set in iOS Settings."
                    )
                    accessibilityItem(
                        icon: "hand.raised.fill",
                        title: "Large Tap Targets",
                        detail: "All interactive elements meet the 44×44pt minimum touch target size."
                    )
                    accessibilityItem(
                        icon: "speaker.wave.2.fill",
                        title: "VoiceOver",
                        detail: "Every button, icon, and control has a descriptive accessibility label."
                    )
                    accessibilityItem(
                        icon: "circle.lefthalf.filled",
                        title: "High Contrast",
                        detail: "Color choices meet WCAG AA contrast ratios for all text."
                    )
                    accessibilityItem(
                        icon: "wind",
                        title: "Reduce Motion",
                        detail: "Toggle in Settings to replace spring/bounce animations with simple fades."
                    )
                }
                .padding(Spacing.lg)
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func accessibilityItem(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.sageGreen)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.cardTitle())
                    .foregroundStyle(Color.textPrimary)
                Text(detail)
                    .font(.bodyText())
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .cardStyle()
    }
}

#Preview {
    SettingsView()
}
