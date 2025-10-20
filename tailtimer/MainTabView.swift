import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: New Dashboard
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            
            // --- Tab 2: Today's Schedule ---
            // This is the one you are looking for
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "list.bullet.clipboard")
                }
            
            // Tab 3: Pets List
            PetsListView()
                .tabItem {
                    Label("Pets", systemImage: "pawprint")
                }
            
            // Tab 4: Calendar
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            // Tab 5: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        // Request notification permission once
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Pet.self, inMemory: true)
}
