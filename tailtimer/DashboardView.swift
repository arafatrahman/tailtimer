import SwiftUI
import SwiftData

struct DashboardView: View {
    // --- Database Queries ---
    @Query private var pets: [Pet]
    @Query private var medications: [Medication]
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]

    // --- State Variables ---
    @State private var showAddOptions = false
    @State private var showAddPetSheet = false
    @State private var showAnalyticsSheet = false

    // --- Binding for selectedTab ---
    @Binding var selectedTab: Int

    // --- Computed Properties ---
    private var scheduledDosesToday: [ScheduledDose] {
        var doses: [ScheduledDose] = []
        let today = Calendar.current.startOfDay(for: .now)
        for med in medications {
            let start = Calendar.current.startOfDay(for: med.startDate)
            let end = Calendar.current.startOfDay(for: med.endDate)
            guard today >= start && today <= end else { continue }
            guard isScheduledForToday(med, today, start) else { continue }
            for time in med.reminderTimes {
                doses.append(ScheduledDose(medication: med, time: time))
            }
        }
        return doses.sorted { $0.time < $1.time }
    }

    private func isScheduledForToday(_ med: Medication, _ today: Date, _ start: Date) -> Bool {
        switch med.frequencyType {
        case "Daily": return true
        case "Weekly":
            let todayWeekday = Calendar.current.component(.weekday, from: today)
            let startWeekday = Calendar.current.component(.weekday, from: start)
            return todayWeekday == startWeekday
        case "Custom Interval":
            if let interval = med.customInterval {
                // Ensure daysSinceStart is not negative before modulo operation
                let daysSinceStart = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
                return daysSinceStart >= 0 && daysSinceStart % interval == 0
            }
            return false
        default: return false
        }
    }

    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        let doseScheduledTime = dose.scheduledTime(on: .now)
        return logs.first { log in
            log.medication?.id == dose.medication.id &&
            log.scheduledTime == doseScheduledTime
        }
    }

    private var remainingDoses: [ScheduledDose] { scheduledDosesToday.filter { logFor(dose: $0) == nil } }
    private var completedDoses: [ScheduledDose] { scheduledDosesToday.filter { logFor(dose: $0) != nil } }
    private var takenCount: Int { completedDoses.filter { logFor(dose: $0)?.status == "taken" }.count }
    private var ignoredCount: Int { completedDoses.filter { logFor(dose: $0)?.status == "missed" }.count }
    private var remainingCount: Int { remainingDoses.count }
    private var overallPerformance: Double {
        let total = scheduledDosesToday.count
        return total == 0 ? 0 : Double(takenCount) / Double(total)
    }
    private var activeMedicationsCount: Int {
        medications.filter { $0.endDate >= .now }.count
    }
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }
    private var currentDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, EEEE" // Format: October 21, Tuesday
        return dateFormatter.string(from: Date())
    }
    private var upcomingAndRecentDoses: [ScheduledDose] {
        let upcoming = remainingDoses.prefix(3)
        let needed = 3 - upcoming.count
        // Ensure needed is not negative if upcoming has 3 or more
        let recentCompleted = completedDoses.suffix(max(0, needed))
        return (upcoming + recentCompleted).sorted { $0.time < $1.time }
    }

    // --- Main Body ---
    var body: some View {
        ZStack { // Use ZStack to overlay the popup
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) { // Reduced spacing

                        // Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text(greeting)
                                    .font(.largeTitle).fontWeight(.bold)
                                Text(currentDateString)
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { showAnalyticsSheet = true } label: {
                                Image(systemName: "chart.pie")
                                    .font(.title2).fontWeight(.semibold)
                                    .padding(10).background(Color(.systemGray5))
                                    .foregroundColor(.primary).clipShape(Circle())
                            }
                            Button { withAnimation(.spring) { showAddOptions = true } } label: {
                                Image(systemName: "plus")
                                    .font(.title2).fontWeight(.semibold)
                                    .padding(10).background(Color(.systemGray5))
                                    .foregroundColor(.primary).clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)

                        // Summary Stats
                        HStack(spacing: 12) {
                             OverviewCard(value: pets.count, label: "Total Pets", color: .purple)
                             OverviewCard(value: activeMedicationsCount, label: "Active Meds", color: .orange)
                        }
                        .padding(.horizontal)

                        // Overall Performance
                        OverallPerformanceView(percentage: overallPerformance)
                            .padding(.horizontal)

                        // Today's Overview
                        HStack(spacing: 12) {
                            OverviewCard(value: remainingCount, label: "To do", color: .blue)
                            OverviewCard(value: takenCount, label: "Done", color: .green)
                            OverviewCard(value: ignoredCount, label: "Skipped", color: Color(.systemGray))
                        }
                        .padding(.horizontal)

                        // Today's Medication
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Today's Medication").font(.title2).fontWeight(.bold)
                                Spacer()
                                Button("See all") { selectedTab = 1 }
                                    .font(.subheadline).fontWeight(.medium)
                            }
                            VStack(spacing: 12) {
                                if upcomingAndRecentDoses.isEmpty && scheduledDosesToday.isEmpty {
                                    Text("No medications scheduled.")
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical)
                                } else {
                                    ForEach(upcomingAndRecentDoses) { dose in
                                        UpcomingMedicationRow(dose: dose, log: logFor(dose: dose))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Your Pets
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Your Pets").font(.title2).fontWeight(.bold)
                                Spacer()
                                Button("See all") { selectedTab = 2 }
                                .font(.subheadline).fontWeight(.medium)
                            }
                            VStack(spacing: 12) {
                                if pets.isEmpty {
                                    Text("Add your first pet.")
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical)
                                } else {
                                    ForEach(pets) { pet in
                                        DashboardPetRow(pet: pet)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                    }
                    .padding(.vertical) // Add padding top/bottom of ScrollView content
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarHidden(true) // Keep nav bar hidden
                // --- Sheets ---
                .sheet(isPresented: $showAddPetSheet) { AddPetView() }
                .sheet(isPresented: $showAnalyticsSheet) { AnalyticsView() }
            }
            .disabled(showAddOptions) // Disable background interaction when popup is shown

            // --- Custom Popup Overlay ---
            if showAddOptions {
                AddOptionsPopupView(
                    addPetAction: {
                        withAnimation { showAddOptions = false }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showAddPetSheet = true }
                    },
                    addMedicationAction: {
                        withAnimation { showAddOptions = false }
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { selectedTab = 2 } // Switch to Pets tab
                    },
                    dismissAction: { withAnimation(.spring) { showAddOptions = false } }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        } // End ZStack
    }
}


// --- Helper Views Below ---

struct OverallPerformanceView: View {
    let percentage: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Overall Performance").font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)
                Spacer()
                Text(percentage.formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
            }
            GeometryReader { geo in
                Capsule().fill(Color(.systemGray5))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(percentage >= 0.7 ? Color.green : (percentage >= 0.4 ? Color.orange : Color.red))
                            .frame(width: max(0, geo.size.width * percentage))
                            .animation(.spring, value: percentage)
                    }
            }
            .frame(height: 6)
        }
    }
}

struct OverviewCard: View {
    let value: Int
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color).contentTransition(.numericText()).animation(.spring, value: value)
            Text(label).font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).background(Color(.systemBackground))
        .cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

struct UpcomingMedicationRow: View {
    let dose: ScheduledDose
    let log: MedicationLog?
    private var pet: Pet? { dose.medication.pet }
    private var isCompleted: Bool { log != nil }
    private var wasTaken: Bool { log?.status == "taken" }
    private var backgroundColor: Color {
        if isCompleted { return wasTaken ? Color.green.opacity(0.15) : Color.red.opacity(0.15) }
        else { return Color(.systemGray6) }
    }
    var body: some View {
        HStack(spacing: 12) {
            Text(pet?.name.prefix(1) ?? "?")
                .font(.headline).fontWeight(.bold).foregroundColor(.white)
                .frame(width: 40, height: 40).background(petColor(for: pet)).clipShape(Circle())
            VStack(alignment: .leading) {
                Text(pet?.name ?? "Unknown Pet").font(.headline)
                Text("\(dose.medication.name), \(dose.medication.dosage)")
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            HStack(spacing: 6) {
                Text(dose.time, style: .time)
                    .font(.headline).fontWeight(.bold)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted, color: .secondary)
                if isCompleted {
                    Image(systemName: wasTaken ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(wasTaken ? .green : .red)
                }
            }
        }
        .padding().background(backgroundColor).cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
    private func petColor(for pet: Pet?) -> Color {
        let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow]
        guard let petName = pet?.name else { return .gray }
        let hash = abs(petName.hashValue); return petColors[hash % petColors.count]
    }
}

struct DashboardPetRow: View {
    let pet: Pet
    var body: some View {
        HStack(spacing: 12) {
            Text(pet.name.prefix(1))
                .font(.headline).fontWeight(.bold).foregroundColor(.white)
                .frame(width: 40, height: 40).background(petColor(for: pet)).clipShape(Circle())
            VStack(alignment: .leading) {
                Text(pet.name).font(.headline)
                Text(pet.breed.isEmpty ? pet.species : pet.breed)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            NavigationLink(destination: PetProfileView(pet: pet)) {
                Text("View").font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(.systemGray5)).cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding().background(Color(.systemGray6))
        .cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
    private func petColor(for pet: Pet?) -> Color {
        let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow]
        guard let petName = pet?.name else { return .gray }
        let hash = abs(petName.hashValue); return petColors[hash % petColors.count]
    }
}

// --- Preview ---
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a constant binding for the preview
        DashboardView(selectedTab: .constant(0))
            .modelContainer(for: [Pet.self, Medication.self, MedicationLog.self], inMemory: true)
    }
}
