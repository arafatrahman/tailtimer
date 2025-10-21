import SwiftUI
import SwiftData

struct CalendarView: View {
    // --- Database Queries (Unchanged) ---
    @Query private var medications: [Medication]
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]

    // --- State Variables (Updated) ---
    @State private var selectedDate: Date = .now
    @State private var showAddOptions = false
    @State private var showAddPetSheet = false
    @State private var medicationToEdit: Medication?

    // --- Binding for Tab Navigation (Unchanged) ---
    @Binding var selectedTab: Int

    // --- Color Theme (ADDED for consistency) ---
    private let primaryColor = Color.blue
    private let accentColor = Color.orange
    private let backgroundColor = Color(.systemGroupedBackground)

    // --- Computed Properties & Helpers (Unchanged) ---
    private let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow]

    private var dosesForSelectedDate: [ScheduledDose] {
        var doses: [ScheduledDose] = []
        let selected = Calendar.current.startOfDay(for: selectedDate)
        for med in medications {
            let start = Calendar.current.startOfDay(for: med.startDate)
            let end = Calendar.current.startOfDay(for: med.endDate)
            guard selected >= start && selected <= end else { continue }
            guard isScheduledForDate(med, selected, start) else { continue }
            for time in med.reminderTimes {
                doses.append(ScheduledDose(medication: med, time: time))
            }
        }
        return doses.sorted { $0.time < $1.time }
    }

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
                return daysBetween >= 0 && daysBetween % interval == 0
            }
            return false
        default: return false
        }
    }

    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        let scheduledTimeOnDate = dose.scheduledTime(on: selectedDate)
        return logs.first { log in
            log.medication?.id == dose.medication.id &&
            log.scheduledTime == scheduledTimeOnDate
        }
    }

    // --- Main Body (UPDATED for interactivity) ---
    var body: some View {
        ZStack {
            NavigationStack {
                // Main content in a VStack
                VStack(spacing: 0) {

                    // --- 1. Header with Title and Button (Gradient Title) ---
                    HStack {
                        Text("Calendar")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            // Gradient foreground style
                            .foregroundStyle(LinearGradient(
                                colors: [accentColor, primaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                        Spacer()
                        Button {
                            withAnimation(.spring) { showAddOptions = true }
                        } label: {
                            Label("Add New", systemImage: "plus.circle.fill")
                                .labelStyle(.iconOnly)
                                .font(.title)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 8)

                    // --- 2. DatePicker and Schedule List (Redesigned) ---
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Schedule for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)

                            if dosesForSelectedDate.isEmpty {
                                Text("No medications scheduled.")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 30)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(dosesForSelectedDate) { dose in
                                        // WRAPPED in a Button to allow editing
                                        Button {
                                            medicationToEdit = dose.medication
                                        } label: {
                                            CalendarMedRow(dose: dose, log: logFor(dose: dose))
                                        }
                                        .buttonStyle(.plain) // Use plain style to maintain card appearance
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .background(backgroundColor)

                }
                .background(backgroundColor)
                .sheet(isPresented: $showAddPetSheet) {
                    AddPetView()
                }
                // ADDED: Sheet to present AddMedicationView for editing
                .sheet(item: $medicationToEdit) { med in
                    // Need to safely check for pet before opening the editor
                    if let pet = med.pet {
                        AddMedicationView(pet: pet, medicationToEdit: med)
                    } else {
                        Text("Error: Pet not found for this medication.")
                    }
                }
            }
            .disabled(showAddOptions)

            // Popup Overlay (Unchanged)
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


// --- CalendarMedRow Helper View (UPDATED Status Color Logic) ---
struct CalendarMedRow: View {
    let dose: ScheduledDose
    let log: MedicationLog?
    private let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow]

    private func petColor(for pet: Pet?) -> Color {
        guard let petName = pet?.name else { return .gray }
        let hash = abs(petName.hashValue); return petColors[hash % petColors.count]
    }
    
    private var statusInfo: (text: String, color: Color) {
        if let log = log {
            return log.status == "taken" ? ("TAKEN", .green) : ("MISSED", .red)
        } else {
            return ("PENDING", .secondary)
        }
    }
    
    // ADDED: New computed property to determine the Capsule color based on status
    private var capsuleColor: Color {
        switch statusInfo.text {
        case "TAKEN":
            return .green
        case "MISSED":
            return .red
        default: // PENDING
            return petColor(for: dose.medication.pet)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 1. Pet Color Indicator (Prominent Vertical Bar - UPDATED COLOR)
            Capsule()
                .fill(capsuleColor) // Use the new status-aware color
                .frame(width: 8, height: 60)
                .padding(.vertical, -10) // Extend slightly for prominence

            // 2. Medication and Pet Info
            VStack(alignment: .leading, spacing: 4) {
                Text(dose.medication.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(dose.medication.pet?.name ?? "Unknown Pet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 3. Time and Status
            VStack(alignment: .trailing, spacing: 4) {
                // Time (Highlighted)
                Text(dose.time, style: .time)
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)
                
                // Status Pill
                Text(statusInfo.text)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(statusInfo.text == "PENDING" ? .secondary : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusInfo.color.opacity(statusInfo.text == "PENDING" ? 0.2 : 1.0))
                    .cornerRadius(8)
            }
        }
        .padding(10) // Padding inside the card
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3) // Slightly richer shadow
    }
}

// --- Preview ---
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(selectedTab: .constant(3))
            .modelContainer(for: [Pet.self, Medication.self, MedicationLog.self], inMemory: true)
    }
}
