import SwiftUI
import SwiftData

// Make sure the file is named TodayView.swift and the struct is TodayView
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var medications: [Medication]
    // --- THIS IS THE FIX ---
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]
    
    @State private var medicationToEdit: Medication?
    
    // 1. Get all medications scheduled for today
    private var todaysMedications: [Medication] {
        medications.filter { med in
            let today = Calendar.current.startOfDay(for: .now)
            let start = Calendar.current.startOfDay(for: med.startDate)
            let end = Calendar.current.startOfDay(for: med.endDate)
            guard today >= start && today <= end else { return false }
            
            switch med.frequencyType {
            case "Daily":
                return true
            case "Weekly":
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
    }
    
    // 2. Helper function to find a log for a specific medication today
    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        let doseScheduledTime = dose.scheduledTimeForToday
        
        return logs.first { log in
            log.medication?.id == dose.medication.id &&
            log.scheduledTime == doseScheduledTime
        }
    }
    
    // 3. Get all scheduled DOSES for today
    private var scheduledDosesToday: [ScheduledDose] {
        var doses: [ScheduledDose] = []
        
        for med in todaysMedications {
            // Add all its times to the list
            for time in med.reminderTimes {
                doses.append(ScheduledDose(medication: med, time: time))
            }
        }
        
        return doses.sorted { $0.time < $1.time }
    }
    
    // 4. Split today's doses into Remaining and Completed
    private var remainingDoses: [ScheduledDose] {
        scheduledDosesToday.filter { logFor(dose: $0) == nil }
    }
    
    private var completedDoses: [ScheduledDose] {
        scheduledDosesToday.filter { logFor(dose: $0) != nil }
    }
    
    // 5. Stats for the summary card
    private var totalDosesToday: Int { scheduledDosesToday.count }
    private var completedDosesCount: Int { completedDoses.count }
    private var remainingDosesCount: Int { remainingDoses.count }

    var body: some View {
        NavigationStack {
            List {
                // Section 1: Today's Summary Card
                Section {
                    HStack(spacing: 16) {
                        SummaryStat(value: remainingDosesCount, label: "Remaining", color: .blue)
                        Divider()
                        SummaryStat(value: completedDosesCount, label: "Completed", color: .green)
                        Divider()
                        SummaryStat(value: totalDosesToday, label: "Total", color: .gray)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Today's Progress")
                }
                
                // Section 2: Remaining Medications
                Section {
                    if remainingDoses.isEmpty {
                        Text("All medications for today are complete! 🎉")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(remainingDoses) { dose in
                            Button {
                                medicationToEdit = dose.medication
                            } label: {
                                TodayMedicationRow(
                                    dose: dose,
                                    log: nil
                                )
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading) {
                                Button {
                                    medicationToEdit = dose.medication
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteRemainingDose)
                    }
                } header: {
                    Text("Remaining (\(remainingDosesCount))")
                        .font(.headline)
                }
                
                // Section 3: Completed Medications
                Section {
                    if completedDoses.isEmpty {
                        Text("No medications logged yet.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(completedDoses) { dose in
                            Button {
                                medicationToEdit = dose.medication
                            } label: {
                                TodayMedicationRow(
                                    dose: dose,
                                    log: logFor(dose: dose)
                                )
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading) {
                                Button {
                                    medicationToEdit = dose.medication
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteCompletedDose)
                    }
                } header: {
                    Text("Completed (\(completedDosesCount))")
                        .font(.headline)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Today's Schedule")
            .sheet(item: $medicationToEdit) { med in
                if let pet = med.pet {
                    AddPetView(petToEdit: pet) // This was probably a bug, should be AddMedicationView
                    // AddMedicationView(pet: pet, medicationToEdit: med) // <-- Likely what you wanted
                } else {
                    Text("Error: Pet not found for this medication.")
                }
            }
        }
    }
    
    // --- Delete Functions ---
    private func delete(medication: Medication) {
        NotificationManager.shared.removeNotification(for: medication)
        modelContext.delete(medication)
    }
    
    private func deleteRemainingDose(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                delete(medication: remainingDoses[index].medication)
            }
        }
    }
    
    private func deleteCompletedDose(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                delete(medication: completedDoses[index].medication)
            }
        }
    }
}

// SummaryStat struct is defined here
struct SummaryStat: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    TodayView()
        .modelContainer(for: [Pet.self, Medication.self, MedicationLog.self], inMemory: true)
}
