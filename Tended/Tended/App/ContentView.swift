import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            MainTabView()
                .fullScreenCover(isPresented: .init(
                    get: { !hasOnboarded },
                    set: { if $0 { hasOnboarded = false } }
                )) {
                    OnboardingView()
                }

            if showSplash {
                SplashScreen()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash screen

private struct SplashScreen: View {
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.creamWhite.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image("AppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.deepForest.opacity(0.15), radius: 12, x: 0, y: 6)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 4) {
                    Text("Tended")
                        .font(.displayTitle(size: 34))
                        .foregroundStyle(Color.deepForest)

                    Text("Care for every creature.")
                        .font(.bodyText())
                        .foregroundStyle(Color.textSecondary)
                }
                .opacity(taglineOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                taglineOpacity = 1.0
            }
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
