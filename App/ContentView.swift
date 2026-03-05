import SwiftUI

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        MainTabView()
            .fullScreenCover(isPresented: .init(
                get: { !hasOnboarded },
                set: { if $0 { hasOnboarded = false } }
            )) {
                OnboardingView()
            }
    }
}

// MARK: - Main tab bar

struct MainTabView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: Int {
        case today    = 0
        case pets     = 1
        case tasks    = 2
        case calendar = 3
        case settings = 4
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(Tab.today)

            PetListView()
                .tabItem {
                    Label("Pets", systemImage: "pawprint.fill")
                }
                .tag(Tab.pets)

            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(Tab.tasks)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Color.sageGreen)
        .onChange(of: selectedTab) {
            HapticStyle.navigation.trigger()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview)
}
