import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Int = 0 // 0 = Dashboard, 1 = Today, etc.

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            DashboardView(selectedTab: $selectedTab) // Pass binding
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
                .tag(0)

            // Tab 2: Today
            TodayView()
                .tabItem { Label("Today", systemImage: "list.bullet.clipboard") }
                .tag(1)

            // Tab 3: Pets
            PetsListView()
                .tabItem { Label("Pets", systemImage: "pawprint") }
                .tag(2)

            // Tab 4: Calendar
            CalendarView(selectedTab: $selectedTab) // Pass binding
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(3)

            // Tab 5: Settings
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(4)
        }
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Pet.self, inMemory: true)
}
