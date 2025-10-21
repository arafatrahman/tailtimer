import SwiftUI
import SwiftData

struct CalendarView: View {
    // --- Database Queries ---
    @Query private var medications: [Medication]
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]

    // --- State Variables ---
    @State private var selectedDate: Date = .now
    @State private var showAddOptions = false
    @State private var showAddPetSheet = false

    // --- Binding for Tab Navigation ---
    @Binding var selectedTab: Int

    // --- Computed Properties & Helpers ---
    private let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow]

    private var dosesForSelectedDate: [ScheduledDose] {
        var doses: [ScheduledDose] = []
        let selected = Calendar.current.startOfDay(for: selectedDate)
        for med in medications {
            let start = Calendar.current.startOfDay(for: med.startDate)
            let end = Calendar.current.startOfDay(for: med.endDate)
            guard selected >= start && selected <= end else { continue }
            guard isScheduledForDate(med, selected, start) else { continue } // Use helper
            for time in med.reminderTimes {
                doses.append(ScheduledDose(medication: med, time: time))
            }
        }
        return doses.sorted { $0.time < $1.time }
    }

    // Renamed helper for clarity
    private func isScheduledForDate(_ med: Medication, _ targetDate: Date, _ startDate: Date) -> Bool {
        switch med.frequencyType {
        case "Daily": return true
        case "Weekly":
            let targetWeekday = Calendar.current.component(.weekday, from: targetDate)
            let startWeekday = Calendar.current.component(.weekday, from: startDate)
            return targetWeekday == startWeekday
        case "Custom Interval":
            if let interval = med.customInterval {
                let daysBetween = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
                return daysBetween >= 0 && daysBetween % interval == 0 // Ensure non-negative
            }
            return false
        default: return false
        }
    }

    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        let scheduledTimeOnDate = dose.scheduledTime(on: selectedDate) // Use selectedDate
        return logs.first { log in
            log.medication?.id == dose.medication.id &&
            log.scheduledTime == scheduledTimeOnDate
        }
    }

    // --- Main Body ---
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)

                    List {
                        Section("Schedule for \(selectedDate.formatted(date: .abbreviated, time: .omitted))") {
                            if dosesForSelectedDate.isEmpty {
                                Text("No medications scheduled.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(dosesForSelectedDate) { dose in
                                    CalendarMedRow(dose: dose, log: logFor(dose: dose))
                                }
                            }
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    .scrollContentBackground(.hidden)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Calendar")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { withAnimation(.spring) { showAddOptions = true } } label: {
                            Image(systemName: "plus")
                                .font(.title3.weight(.semibold))
                                .padding(8).background(Color(.systemGray5))
                                .foregroundColor(.primary).clipShape(Circle())
                        }
                    }
                }
                .sheet(isPresented: $showAddPetSheet) { AddPetView() }
            }
            .disabled(showAddOptions)

            // Popup Overlay
            if showAddOptions {
                AddOptionsPopupView(
                    addPetAction: {
                        withAnimation { showAddOptions = false }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showAddPetSheet = true }
                    },
                    addMedicationAction: {
                        withAnimation { showAddOptions = false }
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { selectedTab = 2 }
                    },
                    dismissAction: { withAnimation(.spring) { showAddOptions = false } }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }
}


// --- CalendarMedRow Helper View ---
struct CalendarMedRow: View {
    let dose: ScheduledDose
    let log: MedicationLog?
    private let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow]

    private func petColor(for pet: Pet?) -> Color {
        guard let petName = pet?.name else { return .gray }
        let hash = abs(petName.hashValue); return petColors[hash % petColors.count]
    }

    var body: some View {
         HStack(spacing: 12) {
            Circle().fill(petColor(for: dose.medication.pet)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(dose.medication.name).font(.headline)
                Text(dose.medication.pet?.name ?? "Unknown").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(dose.time, style: .time).font(.subheadline).fontWeight(.medium)
                if let log = log {
                    Text(log.status == "taken" ? "Taken" : "Ignored").font(.caption).fontWeight(.bold)
                        .foregroundStyle(log.status == "taken" ? .green : .red)
                } else {
                    Text("Pending").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// --- Preview ---
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(selectedTab: .constant(3))
            .modelContainer(for: [Pet.self, Medication.self, MedicationLog.self], inMemory: true)
    }
}
