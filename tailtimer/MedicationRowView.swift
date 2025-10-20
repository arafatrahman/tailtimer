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
                
                // --- UPDATED: Show all times ---
                Text(formattedTimes())
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
            
            Spacer()
            
            Image(systemName: "pills.fill")
                .font(.title)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 8)
    }
    
    // --- UPDATED: Helper function to format times ---
    private func formattedTimes() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        // Map all dates to their time string and join them with ", "
        return medication.reminderTimes
            .sorted()
            .map { formatter.string(from: $0) }
            .joined(separator: ", ")
    }
}
