import SwiftUI
import SwiftData

// Define the AppTheme enum globally so we can access it from SettingsView and here
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System Default"
    case light = "Light"
    case dark = "Dark"
    var id: Self { self }
    
    // Helper to map enum to SwiftUI's ColorScheme?
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}


@main
struct PetMedsApp: App {
    
    // Read the stored theme from UserDefaults/AppStorage
    @AppStorage("appTheme") var storedTheme: String = AppTheme.system.rawValue
    
    // Computed property to determine which ColorScheme to apply
    var selectedColorScheme: ColorScheme? {
        // Safely initialize AppTheme from the stored string and get its scheme
        AppTheme(rawValue: storedTheme)?.colorScheme
    }
    
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
            MainTabView()
                // Apply the persistent color scheme to the entire app
                .preferredColorScheme(selectedColorScheme)
        }
        .modelContainer(sharedModelContainer) // This injects the database into your app
    }
}
