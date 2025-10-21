import SwiftUI
import SwiftData

struct DashboardView: View {
    // --- Database Queries ---
    @Query private var pets: [Pet]
    @Query private var medications: [Medication]
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]
    
    // --- Computed Properties for Dashboard Stats ---
    
    // 1. Stat Card Data
    private var activeMedications: Int {
        medications.filter { $0.endDate >= .now }.count
    }
    
    // 2. Adherence Data
    private var allTimeTaken: Int {
        logs.filter { $0.status == "taken" }.count
    }
    private var allTimeTotalLogged: Int {
        logs.count
    }
    private var overallAdherence: Double {
        if allTimeTotalLogged == 0 { return 100.0 } // Start at 100%
        return (Double(allTimeTaken) / Double(allTimeTotalLogged)) * 100.0
    }
    
    // 3. Upcoming Doses Data (logic copied from TodayView)
    private var remainingDosesToday: [ScheduledDose] {
        scheduledDosesToday.filter { logFor(dose: $0) == nil }
    }
    
    private var scheduledDosesToday: [ScheduledDose] {
        var doses: [ScheduledDose] = []
        let today = Calendar.current.startOfDay(for: .now)
        
        for med in medications {
            let start = Calendar.current.startOfDay(for: med.startDate)
            let end = Calendar.current.startOfDay(for: med.endDate)
            guard today >= start && today <= end else { continue }
            
            // Check frequency
            switch med.frequencyType {
            case "Daily":
                break
            case "Weekly":
                let todayWeekday = Calendar.current.component(.weekday, from: today)
                let startWeekday = Calendar.current.component(.weekday, from: start)
                guard todayWeekday == startWeekday else { continue }
            case "Custom Interval":
                if let interval = med.customInterval {
                    let daysSinceStart = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
                    guard daysSinceStart % interval == 0 else { continue }
                } else {
                    continue
                }
            default:
                continue
            }
            
            // Add all times
            for time in med.reminderTimes {
                doses.append(ScheduledDose(medication: med, time: time))
            }
        }
        return doses.sorted { $0.time < $1.time }
    }
    
    // --- THIS IS THE FIX ---
    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        // Change scheduledTimeForToday to scheduledTime(on: .now)
        let doseScheduledTime = dose.scheduledTime(on: .now)
        return logs.first { log in
            log.medication?.id == dose.medication.id &&
            log.scheduledTime == doseScheduledTime
        }
    }
    // --- END OF FIX ---
    
    // --- Main Body ---
    var body: some View {
        NavigationStack {
            List {
                // --- Section 1: Quick Stats ---
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            StatCard(
                                value: "\(pets.count)",
                                label: "Total Pets",
                                symbol: "pawprint.fill",
                                color: .blue
                            )
                            StatCard(
                                value: "\(activeMedications)",
                                label: "Active Meds",
                                symbol: "pills.fill",
                                color: .purple
                            )
                            StatCard(
                                value: "\(remainingDosesToday.count)",
                                label: "Doses Left Today",
                                symbol: "list.bullet.clipboard.fill",
                                color: .orange
                            )
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } header: {
                    Text("At a Glance")
                }

                // --- Section 2: Overall Adherence ---
                Section("Overall Adherence") {
                    DashboardAdherenceGauge(percentage: overallAdherence)
                }
                
                // --- Section 3: Pet Overview ---
                Section("My Pets") {
                    if pets.isEmpty {
                        Text("No pets added yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pets) { pet in
                            NavigationLink(destination: PetProfileView(pet: pet)) {
                                PetDashboardRow(pet: pet)
                            }
                        }
                    }
                }
                
                // --- Section 4: Upcoming Doses ---
                Section("What's Next (Today)") {
                    if remainingDosesToday.isEmpty {
                        Text("No more doses scheduled for today! 👍")
                            .foregroundStyle(.secondary)
                    } else {
                        // Show the next 5 upcoming doses
                        ForEach(remainingDosesToday.prefix(5)) { dose in
                            UpcomingDoseRow(dose: dose)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Dashboard")
        }
    }
}


// --- (Helper Views are unchanged) ---
struct StatCard: View {
    let value: String
    let label: String
    let symbol: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).font(.title2).foregroundColor(color)
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 140, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DashboardAdherenceGauge: View {
    let percentage: Double
    
    private var color: Color {
        if percentage >= 90 { return .green }
        if percentage >= 70 { return .yellow }
        return .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("All-Time Performance").font(.headline)
                Spacer()
                Text(String(format: "%.0f%%", percentage))
                    .font(.title3).fontWeight(.bold).foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule().fill(color)
                        .frame(width: max(0, geo.size.width * (percentage / 100.0)))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
                }
                .frame(height: 12)
            }
            .frame(height: 12)
        }
        .padding(.vertical, 8)
    }
}

struct PetDashboardRow: View {
    let pet: Pet
    
    var body: some View {
        HStack {
            if let photoData = pet.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage).resizable().scaledToFill()
                    .frame(width: 45, height: 45).clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill").resizable().scaledToFit()
                    .frame(width: 45, height: 45).foregroundStyle(.gray.opacity(0.6))
            }
            VStack(alignment: .leading) {
                Text(pet.name).font(.headline)
                Text("\(pet.medications?.count ?? 0) active medications")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct UpcomingDoseRow: View {
    let dose: ScheduledDose
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(dose.medication.name).font(.headline)
                Text(dose.medication.pet?.name ?? "Unknown Pet")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(dose.time, style: .time)
                .font(.subheadline).fontWeight(.medium).foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Pet.self, Medication.self, MedicationLog.self], inMemory: true)
}
