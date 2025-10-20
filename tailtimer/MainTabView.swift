import SwiftUI
import SwiftData // <-- FIX: Added import

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: Dashboard (the new "home")
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "list.bullet.clipboard")
                }
            
            // Tab 2: Pets List
            PetsListView()
                .tabItem {
                    Label("Pets", systemImage: "pawprint")
                }
            
            // Tab 3: Calendar
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            // Tab 4: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        // Request notification permission once, when the main app view appears
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Pet.self, inMemory: true) // This line now works
}
