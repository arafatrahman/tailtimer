import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var medications: [Medication]
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]
    
    // Computed property to find medications scheduled for today
    private var todaysMedications: [Medication] {
        medications.filter { med in
            // 1. Is it within the start/end date range?
            let today = Calendar.current.startOfDay(for: .now)
            let start = Calendar.current.startOfDay(for: med.startDate)
            let end = Calendar.current.startOfDay(for: med.endDate)
            
            guard today >= start && today <= end else {
                return false
            }
            
            // 2. Is it scheduled for today based on frequency?
            // (Simplified: For now, we only support "Daily")
            // We can add "Weekly" and "Custom" logic here later
            switch med.frequencyType {
            case "Daily":
                return true
            case "Weekly":
                // Check if today's weekday matches the start date's weekday
                let todayWeekday = Calendar.current.component(.weekday, from: today)
                let startWeekday = Calendar.current.component(.weekday, from: start)
                return todayWeekday == startWeekday
            case "Custom Interval":
                if let interval = med.customInterval {
                    let daysSinceStart = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
                    return daysSinceStart % interval == 0
                }
                return false
            default:
                return false
            }
        }
        .sorted { $0.reminderTime < $1.reminderTime } // Sort by time
    }
    
    // Helper function to check if a med was already logged today
    private func logForToday(medication: Medication) -> MedicationLog? {
        logs.first { log in
            // Is the log for the same medication AND was it logged today?
            log.medication?.id == medication.id &&
            Calendar.current.isDateInToday(log.date)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Today's Schedule") {
                    if todaysMedications.isEmpty {
                        Text("No medications scheduled for today.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todaysMedications) { med in
                            TodayMedicationRow(
                                medication: med,
                                log: logForToday(medication: med) // Pass in today's log, if it exists
                            )
                        }
                    }
                }
            }
            .navigationTitle("Today's Schedule")
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Pet.self, Medication.self, MedicationLog.self], inMemory: true)
}
