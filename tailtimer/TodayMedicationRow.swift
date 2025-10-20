import SwiftUI
import SwiftData

struct TodayMedicationRow: View {
    @Environment(\.modelContext) private var modelContext
    let dose: ScheduledDose
    let log: MedicationLog?
    
    private var status: String {
        log?.status ?? "pending"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dose.medication.name)
                    .font(.headline)
                    .strikethrough(status == "taken")
                
                Text(dose.medication.pet?.name ?? "Pet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(dose.time, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
            }
            
            Spacer()
            
            if status == "pending" {
                Button {
                    markAsTaken(true)
                } label: {
                    Label("Take", systemImage: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                
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
            else if status == "taken" {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Taken")
                }
                .font(.subheadline)
                .foregroundStyle(.green)
            }
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
    
    private func markAsTaken(_ didTake: Bool) {
        withAnimation {
            let status = didTake ? "taken" : "missed"
            
            let newLog = MedicationLog(
                date: .now,
                status: status,
                scheduledTime: dose.scheduledTimeForToday
            )
            
            newLog.medication = dose.medication
            modelContext.insert(newLog)
        }
    }
}
