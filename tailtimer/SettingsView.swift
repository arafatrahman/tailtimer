import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation // For UserDefaults (used by @AppStorage)

// Note: The AppTheme enum must be defined in PetMedsApp.swift or a global file.
// We include it here for context but assume it's accessible globally.
/* enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System Default"
    case light = "Light"
    case dark = "Dark"
    var id: Self { self }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
*/

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Read/Write persistent states
    @AppStorage("appTheme") private var storedTheme: String = "System Default"
    @AppStorage("isSoundEnabled") private var storedSound: Bool = true
    @AppStorage("snoozeDuration") private var storedSnoozeDuration: Int = 5 // Duration in minutes
    
    // Internal UI States
    @State private var selectedTheme: AppTheme = .system
    @State private var isSoundEnabled: Bool = true
    @State private var selectedSnoozeDuration: Int = 5
    
    // Backup/Restore States (Used for UI flow, logic in helper structs)
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var importedPets: [Pet]?
    @State private var showRestoreConfirmation = false
    
    private let snoozeOptions = [5, 10, 15, 30] // Options in minutes

    var body: some View {
        NavigationStack {
            List {
                // --- Section 1: Reminders & Notifications ---
                Section("Reminders & Notifications") {
                    // ACTIONABLE NOTIFICATION LINK
                    Button {
                        // Open iOS Settings directly for this app
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Manage App Notification Permissions")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Toggle for notification sound
                    Toggle("Notification Sound", isOn: $isSoundEnabled)
                        .onChange(of: isSoundEnabled) { _, newValue in
                            storedSound = newValue // Save to AppStorage
                            // ACTION: You should add logic here to call NotificationManager.rescheduleAll()
                            print("Notification sound preference saved: \(newValue)")
                        }
                    
                    // Snooze Duration Picker
                    Picker("Snooze Duration", selection: $selectedSnoozeDuration) {
                        ForEach(snoozeOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .onChange(of: selectedSnoozeDuration) { _, newValue in
                        storedSnoozeDuration = newValue // Save to AppStorage
                        print("Snooze duration saved: \(newValue) min")
                    }
                }
                
                // --- Section 2: App Theme (ACTIONABLE) ---
                Section("App Theme") {
                    Picker("Appearance", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedTheme) { _, newTheme in
                        storedTheme = newTheme.rawValue // Save to AppStorage
                    }
                }
                
                // --- Section 3: Data Management (Backup/Restore) ---
                Section("Data Management") {
                    Button { isExporting.toggle() } label: { Label("Backup Data", systemImage: "archivebox.arrow.up") }
                    Button(role: .destructive) { isImporting.toggle() } label: { Label("Restore from Backup", systemImage: "archivebox.arrow.down") }
                }
            }
            .navigationTitle("Settings")
            // Apply the selected theme
            .preferredColorScheme(selectedTheme.colorScheme)
            
            // --- File Handlers and Alerts (Unchanged) ---
            .fileExporter(
                isPresented: $isExporting,
                document: BackupDocument(context: modelContext),
                contentType: .json,
                defaultFilename: "PetMedsBackup-\(formattedDate()).json"
            ) { result in
                switch result {
                case .success: presentAlert(title: "Backup Complete", message: "Your data has been successfully exported.")
                case .failure(let error): print("Export error: \(error)"); presentAlert(title: "Backup Failed", message: "Could not export data.")
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    do {
                        let data = try Data(contentsOf: url)
                        self.importedPets = try BackupManager.decode(from: data)
                        self.showRestoreConfirmation = true
                    } catch {
                        presentAlert(title: "Restore Failed", message: "File is invalid.")
                    }
                case .failure(let error): print("Import error: \(error)"); presentAlert(title: "Import Failed", message: "Could not import file.")
                }
            }
            .alert(alertTitle, isPresented: $showAlert) { Button("OK") { } } message: { Text(alertMessage) }
            .alert("Are you sure?", isPresented: $showRestoreConfirmation) {
                Button("Proceed & Overwrite", role: .destructive) {
                    if let pets = importedPets {
                        BackupManager.restore(from: pets, context: modelContext)
                        presentAlert(title: "Restore Complete", message: "Your data has been restored.")
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Restoring from a backup will delete all current data in the app. This action cannot be undone.") }
        }
        // Initialize state from AppStorage on load
        .onAppear {
            if let theme = AppTheme(rawValue: storedTheme) {
                selectedTheme = theme
            }
            isSoundEnabled = storedSound
            selectedSnoozeDuration = storedSnoozeDuration
        }
    }
    
    // Helper functions (omitted for brevity, assume they exist)
    private func presentAlert(title: String, message: String) { self.alertTitle = title; self.alertMessage = message; self.showAlert = true }
    private func formattedDate() -> String { let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; return formatter.string(from: .now) }
}


// --- BackupDocument Helper (Required for file operations) ---
// (Assume the required BackupManager and other models are accessible)
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data?

    init(context: ModelContext) {
        do { self.data = try BackupManager.encode(context: context) } catch { self.data = nil }
    }
    init(configuration: ReadConfiguration) throws { self.data = configuration.file.regularFileContents }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = data else { throw CocoaError(.fileWriteUnknown) }
        return FileWrapper(regularFileWithContents: data)
    }
}
