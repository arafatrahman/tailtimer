import SwiftUI
import SwiftData // <-- FIX: Added import

struct TodayMedicationRow: View {
    @Environment(\.modelContext) private var modelContext
    let medication: Medication
    let log: MedicationLog? // Today's log, if one exists
    
    // Get the status from the log, or "pending" if no log exists
    private var status: String {
        log?.status ?? "pending"
    }
    
    var body: some View {
        HStack {
            // Pet and Med Info
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                    .strikethrough(status == "taken") // Strikethrough if taken
                
                Text(medication.pet?.name ?? "Pet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(medication.reminderTime, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
            }
            
            Spacer()
            
            // --- Action Buttons ---
            
            // If no log exists (pending), show Take/Skip
            if status == "pending" {
                // "Take" Button
                Button {
                    markAsTaken(true)
                } label: {
                    Label("Take", systemImage: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                
                // "Skip" Button
                Button {
                    markAsTaken(false)
                } label: {
                    Label("Skip", systemImage: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            // If already taken, show a confirmation
            else if status == "taken" {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Taken")
                }
                .font(.subheadline)
                .foregroundStyle(.green)
            }
            // If skipped, show that
            else if status == "missed" {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Skipped")
                }
                .font(.subheadline)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Function to create the log entry
    private func markAsTaken(_ didTake: Bool) {
        withAnimation {
            let status = didTake ? "taken" : "missed"
            let newLog = MedicationLog(date: .now, status: status)
            
            // Link the log to the medication
            newLog.medication = medication
            
            // Insert the log into the database
            modelContext.insert(newLog) // This line now works
        }
    }
}
