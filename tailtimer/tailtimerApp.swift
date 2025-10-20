import SwiftUI
import SwiftData

@main
struct PetMedsApp: App {
    // This container holds all your app's data
    var sharedModelContainer: ModelContainer = {
        // The Schema defines all the models your app will use
        let schema = Schema([
            Pet.self,
            Medication.self,
            HealthNote.self,
            MedicationLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // This is the only line that changes.
            // We now point to MainTabView instead of HomeView.
            MainTabView()
        }
        .modelContainer(sharedModelContainer) // This injects the database into your app
    }
}
