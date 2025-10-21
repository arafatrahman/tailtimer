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

    // --- Color Theme ---
    private let primaryColor = Color.blue
    private let secondaryColor = Color.purple
    private let accentColor = Color.orange
    private let backgroundColor = Color(.systemGroupedBackground)
    
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
        dateFormatter.dateFormat = "MMMM d, EEEE"
        return dateFormatter.string(from: Date())
    }
    private var upcomingAndRecentDoses: [ScheduledDose] {
        let upcoming = remainingDoses.prefix(3)
        let needed = 3 - upcoming.count
        let recentCompleted = completedDoses.suffix(max(0, needed))
        return (upcoming + recentCompleted).sorted { $0.time < $1.time }
    }

    // --- Main Body ---
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header Section
                        headerSection
                        
                        // Quick Stats Cards
                        quickStatsSection
                        
                        // Performance Section
                        performanceSection
                        
                        // Today's Progress
                        todayProgressSection
                        
                        // Medications Section
                        medicationsSection
                        
                        // Pets Section
                        petsSection
                    }
                    .padding(.vertical)
                }
                .background(backgroundColor)
                .navigationBarHidden(true)
                .sheet(isPresented: $showAddPetSheet) { AddPetView() }
                .sheet(isPresented: $showAnalyticsSheet) { AnalyticsView() }
            }
            .disabled(showAddOptions)

            // Add Options Popup
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                Text(currentDateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 12) {
                Button { showAnalyticsSheet = true } label: {
                    Image(systemName: "chart.pie.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(secondaryColor)
                        .clipShape(Circle())
                        .shadow(color: secondaryColor.opacity(0.3), radius: 4, y: 2)
                }
                Button { withAnimation(.spring) { showAddOptions = true } } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(accentColor)
                        .clipShape(Circle())
                        .shadow(color: accentColor.opacity(0.3), radius: 4, y: 2)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                value: pets.count,
                label: "Total Pets",
                icon: "pawprint.fill",
                color: .purple,
                gradient: [.purple, .indigo]
            )
            
            StatCard(
                value: activeMedicationsCount,
                label: "Active Meds",
                icon: "pills.fill",
                color: .orange,
                gradient: [.orange, .red]
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Medication Performance")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Your overall adherence rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(overallPerformance.formatted(.percent.precision(.fractionLength(0))))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(performanceColor)
            }
            
            PerformanceBar(percentage: overallPerformance)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }
    
    private var performanceColor: Color {
        switch overallPerformance {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    // MARK: - Today's Progress Section
    private var todayProgressSection: some View {
        HStack(spacing: 12) {
            ProgressCard(
                value: remainingCount,
                label: "To Do",
                icon: "clock.fill",
                color: .blue,
                gradient: [.blue, .cyan]
            )
            
            ProgressCard(
                value: takenCount,
                label: "Completed",
                icon: "checkmark.circle.fill",
                color: .green,
                gradient: [.green, .mint]
            )
            
            ProgressCard(
                value: ignoredCount,
                label: "Missed",
                icon: "xmark.circle.fill",
                color: .red,
                gradient: [.red, .orange]
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Medications Section
    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Today's Medication",
                actionTitle: "See All",
                action: { selectedTab = 1 }
            )
            
            if upcomingAndRecentDoses.isEmpty && scheduledDosesToday.isEmpty {
                EmptyStateView(
                    icon: "pills",
                    title: "No Medications",
                    message: "No medications scheduled for today"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(upcomingAndRecentDoses) { dose in
                        MedicationCard(dose: dose, log: logFor(dose: dose))
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Pets Section
    private var petsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Your Pets",
                actionTitle: "See All",
                action: { selectedTab = 2 }
            )
            
            if pets.isEmpty {
                EmptyStateView(
                    icon: "pawprint",
                    title: "No Pets Added",
                    message: "Add your first pet to get started"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(pets) { pet in
                        PetCard(pet: pet)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: color.opacity(0.3), radius: 8, y: 4)
    }
}

struct ProgressCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct PerformanceBar: View {
    let percentage: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * percentage))
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: percentage)
            }
        }
        .frame(height: 8)
    }
}

struct SectionHeader: View {
    let title: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: action) {
                HStack(spacing: 4) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
            }
        }
    }
}

struct MedicationCard: View {
    let dose: ScheduledDose
    let log: MedicationLog?
    
    private var pet: Pet? { dose.medication.pet }
    private var isCompleted: Bool { log != nil }
    private var wasTaken: Bool { log?.status == "taken" }
    private var statusColor: Color {
        if isCompleted {
            return wasTaken ? .green : .red
        } else {
            return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Pet Avatar
            ZStack {
                Circle()
                    .fill(petColor(for: pet).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(pet?.name.prefix(1) ?? "?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(petColor(for: pet))
            }
            
            // Medication Info
            VStack(alignment: .leading, spacing: 4) {
                Text(pet?.name ?? "Unknown Pet")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(dose.medication.name) • \(dose.medication.dosage)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Time and Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(dose.time, style: .time)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
                
                if isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: wasTaken ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(wasTaken ? "Taken" : "Missed")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(statusColor)
                } else {
                    Text("Upcoming")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func petColor(for pet: Pet?) -> Color {
        let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .mint]
        guard let petName = pet?.name else { return .gray }
        let hash = abs(petName.hashValue)
        return petColors[hash % petColors.count]
    }
}

struct PetCard: View {
    let pet: Pet
    
    var body: some View {
        HStack(spacing: 16) {
            // Pet Avatar
            ZStack {
                Circle()
                    .fill(petColor(for: pet).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(pet.name.prefix(1))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(petColor(for: pet))
            }
            
            // Pet Info
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(pet.breed.isEmpty ? pet.species : "\(pet.species) • \(pet.breed)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // View Button
            NavigationLink(destination: PetProfileView(pet: pet)) {
                Text("View")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func petColor(for pet: Pet) -> Color {
        let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .mint]
        let hash = abs(pet.name.hashValue)
        return petColors[hash % petColors.count]
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .opacity(0.5)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(selectedTab: .constant(0))
            .modelContainer(for: [Pet.self, Medication.self, MedicationLog.self], inMemory: true)
    }
}
