import SwiftUI

struct MedicationRowView: View {
    let medication: Medication
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                
                Text(medication.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Next dose: \(formattedNextDose())")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            // We can add a "Mark as Taken" button here later
            Image(systemName: "pills.fill")
                .font(.title)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 8)
    }
    
    // Helper function to format the time
    private func formattedNextDose() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: medication.reminderTime)
    }
}
