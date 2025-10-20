import SwiftUI
import UniformTypeIdentifiers
import SwiftData // <-- FIX: Added import

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // State for file operations
    @State private var isExporting = false
    @State private var isImporting = false
    
    // State for alerts
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    // State to hold imported data before confirming the restore
    @State private var importedPets: [Pet]?
    @State private var showRestoreConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    // Placeholders for future features
                    Text("Notification Preferences")
                    Text("Theme Selection")
                }
                
                Section("Data Management") {
                    // Backup Button
                    Button {
                        isExporting.toggle()
                    } label: {
                        Label("Backup Data", systemImage: "archivebox.arrow.up")
                    }
                    
                    // Restore Button
                    Button(role: .destructive) {
                        isImporting.toggle()
                    } label: {
                        Label("Restore from Backup", systemImage: "archivebox.arrow.down")
                    }
                }
            }
            .navigationTitle("Settings")
            // --- Modifiers for File Handling ---
            
            // 1. File Exporter (for backup)
            .fileExporter(
                isPresented: $isExporting,
                document: BackupDocument(context: modelContext), // This line now works
                contentType: .json,
                defaultFilename: "PetMedsBackup-\(formattedDate()).json"
            ) { result in
                switch result {
                case .success:
                    presentAlert(title: "Backup Complete", message: "Your data has been successfully exported.")
                case .failure(let error):
                    presentAlert(title: "Backup Failed", message: "Could not export data. Error: \(error.localizedDescription)")
                }
            }
            
            // 2. File Importer (for restore)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    do {
                        // Read the data from the selected file
                        let data = try Data(contentsOf: url)
                        // Decode it into Pet objects
                        self.importedPets = try BackupManager.decode(from: data)
                        // Show the final warning before overwriting everything
                        self.showRestoreConfirmation = true
                    } catch {
                        presentAlert(title: "Restore Failed", message: "The selected file could not be read or is not a valid backup file.")
                    }
                case .failure(let error):
                    presentAlert(title: "Import Failed", message: "Could not import file. Error: \(error.localizedDescription)")
                }
            }
            
            // --- Alerts ---
            
            // A. Generic success/failure alert
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            
            // B. Restore confirmation alert (CRITICAL)
            .alert("Are you sure?", isPresented: $showRestoreConfirmation) {
                Button("Proceed & Overwrite", role: .destructive) {
                    if let pets = importedPets {
                        // If user confirms, perform the restore
                        BackupManager.restore(from: pets, context: modelContext)
                        presentAlert(title: "Restore Complete", message: "Your data has been restored.")
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Restoring from a backup will delete all current data in the app. This action cannot be undone.")
            }
        }
    }
    
    // Helper to present alerts
    private func presentAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showAlert = true
    }
    
    // Helper to format the date for the default filename
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }
}


// --- Helper Struct for File Exporter ---
// This struct makes our data conform to what the .fileExporter needs
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data?

    init(context: ModelContext) { // This line now works
        do {
            self.data = try BackupManager.encode(context: context)
        } catch { // This block is now reachable
            print("Failed to encode data for backup document: \(error)")
            self.data = nil
        }
    }
    
    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = data else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
