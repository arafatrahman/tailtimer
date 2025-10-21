import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var medications: [Medication]
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]
    
    @State private var medicationToEdit: Medication?
    @State private var visibleSection: TimePeriod? = .none
    
    @State private var showToast: Bool = false
    @State private var toastInfo: ToastInfo? = nil
    
    // --- (New properties for consistent styling from DashboardView) ---
    private let primaryColor = Color.blue
    private let secondaryColor = Color.purple
    private let accentColor = Color.orange
    private let backgroundColor = Color(.systemGroupedBackground)

    private var currentDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, EEEE"
        return dateFormatter.string(from: Date())
    }
    
    private var todayHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Schedule")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [accentColor, primaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                Text(currentDateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // --- (Computed properties and helper functions are unchanged) ---
    
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
                return daysSinceStart % interval == 0
            }
            return false
        default: return false
        }
    }

    private func doses(for period: TimePeriod) -> [ScheduledDose] {
        scheduledDosesToday.filter { dose in
            let hour = Calendar.current.component(.hour, from: dose.time)
            switch period {
            case .morning: return hour >= 5 && hour < 12
            case .afternoon: return hour >= 12 && hour < 17
            case .evening: return hour >= 17 && hour < 21
            case .night: return hour >= 21 || hour < 5
            }
        }
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // 1. Custom Header
                        todayHeader
                            .padding(.top)

                        // 2. Progress Header
                        TodayProgressHeader(
                            totalDoses: totalDosesToday,
                            taken: takenCount,
                            Missed: MissedCount,
                            // FIX: Pass the computed property here
                            remainingCount: remainingCount
                        )
                        .padding(.horizontal)
                        
                        // --- (Sections wrapped in a VStack for horizontal padding) ---
                        VStack(spacing: 12) {
                            TodaySection(
                                period: .morning,
                                doses: doses(for: .morning),
                                logs: logs,
                                onMark: markAsTaken,
                                onEdit: { med in medicationToEdit = med },
                                onDelete: deleteMedication
                            )
                            
                            TodaySection(
                                period: .afternoon,
                                doses: doses(for: .afternoon),
                                logs: logs,
                                onMark: markAsTaken,
                                onEdit: { med in medicationToEdit = med },
                                onDelete: deleteMedication
                            )
                            
                            TodaySection(
                                period: .evening,
                                doses: doses(for: .evening),
                                logs: logs,
                                onMark: markAsTaken,
                                onEdit: { med in medicationToEdit = med },
                                onDelete: deleteMedication
                            )
                            
                            TodaySection(
                                period: .night,
                                doses: doses(for: .night),
                                logs: logs,
                                onMark: markAsTaken,
                                onEdit: { med in medicationToEdit = med },
                                onDelete: deleteMedication
                            )
                        }
                        .padding(.horizontal)

                    }
                    .padding(.vertical)
                }
                .background(backgroundColor) // Use the Dashboard background color
                // Hide the default navigation bar for the custom header
                .navigationBarHidden(true)
                .sheet(item: $medicationToEdit) { med in
                    if let pet = med.pet {
                        AddMedicationView(pet: pet, medicationToEdit: med)
                    } else {
                        Text("Error: Pet not found for this medication.")
                    }
                }
                .onAppear {
                    visibleSection = TimePeriod.current
                }
            }
            
            if showToast, let info = toastInfo {
                AnimatedToastView(info: info, isShowing: $showToast)
            }
        }
    }
    
    // --- (Stats & Logic functions are unchanged) ---
    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        // --- UPDATED ---
        let doseScheduledTime = dose.scheduledTime(on: .now)
        return logs.first { log in
            log.medication?.id == dose.medication.id &&
            log.scheduledTime == doseScheduledTime
        }
    }
    
    private var totalDosesToday: Int {
        scheduledDosesToday.count
    }
    
    private var completedDoses: [ScheduledDose] {
        scheduledDosesToday.filter { logFor(dose: $0) != nil }
    }
    
    private var takenCount: Int {
        completedDoses.filter { logFor(dose: $0)?.status == "taken" }.count
    }
    
    private var MissedCount: Int {
        completedDoses.filter { logFor(dose: $0)?.status == "missed" }.count
    }
    
    // The calculated property used to be here, which is fine, but it needs to be passed down.
    private var remainingCount: Int {
        scheduledDosesToday.filter { logFor(dose: $0) == nil }.count
    }
    
    private var progress: Double {
        let total = totalDosesToday
        let taken = Double(takenCount)
        return total == 0 ? 0.0 : taken / Double(total)
    }
    
    private func markAsTaken(dose: ScheduledDose, status: Bool) {
        withAnimation(.spring) {
            let newStatus = status ? "taken" : "missed"
            let newLog = MedicationLog(
                date: .now,
                status: newStatus,
                // --- UPDATED ---
                scheduledTime: dose.scheduledTime(on: .now)
            )
            newLog.medication = dose.medication
            modelContext.insert(newLog)
            
            self.toastInfo = ToastInfo(
                symbol: status ? "checkmark.circle.fill" : "xmark.circle.fill",
                text: status ? "Marked as Taken!" : "Marked as Missed",
                color: status ? .green : .red
            )
            self.showToast = true
        }
    }
    
    private func deleteMedication(medication: Medication) {
        withAnimation {
            NotificationManager.shared.removeNotification(for: medication)
            modelContext.delete(medication)
        }
    }
}

// --- (Enum remains the same) ---

enum TimePeriod: String, CaseIterable {
    case morning = "Morning", afternoon = "Afternoon", evening = "Evening", night = "Night"
    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .afternoon: return "cloud.sun.fill"
        case .evening: return "moon.stars.fill"
        case .night: return "moon.fill"
        }
    }
    var color: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .blue
        case .evening: return .indigo
        case .night: return .purple
        }
    }
    static var current: TimePeriod {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}

// --- TodaySection (Reused from previous design) ---
struct TodaySection: View {
    let period: TimePeriod
    let doses: [ScheduledDose]
    let logs: [MedicationLog]
    
    var onMark: (ScheduledDose, Bool) -> Void
    var onEdit: (Medication) -> Void
    var onDelete: (Medication) -> Void
    
    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        let doseScheduledTime = dose.scheduledTime(on: .now)
        return logs.first { log in
            log.medication?.id == dose.medication.id &&
            log.scheduledTime == doseScheduledTime
        }
    }
    
    private var remainingDoses: [ScheduledDose] {
        doses.filter { logFor(dose: $0) == nil }.sorted(by: { $0.time < $1.time })
    }
    private var completedDoses: [ScheduledDose] {
        doses.filter { logFor(dose: $0) != nil }.sorted(by: { $0.time < $1.time })
    }
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        if !doses.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                
                // Header Content
                HStack(spacing: 12) {
                    Image(systemName: period.icon)
                        .font(.title2).foregroundColor(.white).frame(width: 30)
                        .padding(8)
                        .background(period.color)
                        .clipShape(Circle())
                    
                    Text(period.rawValue).font(.title2).fontWeight(.bold)
                    Spacer()
                    Text("\(completedDoses.count)/\(doses.count) Completed")
                        .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
                }
                .padding([.horizontal, .top], 16)

                // Inner content (The medication rows)
                VStack(spacing: 12) {
                    ForEach(remainingDoses) { dose in
                        TodayMedicationRow(dose: dose, log: nil, onMark: onMark, onEdit: onEdit)
                            .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { onDelete(dose.medication) } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                    
                    if !completedDoses.isEmpty {
                        DisclosureGroup(isExpanded: $isExpanded.animation(.spring)) {
                            VStack(spacing: 12) {
                                ForEach(completedDoses) { dose in
                                    TodayMedicationRow(dose: dose, log: logFor(dose: dose), onMark: onMark, onEdit: onEdit)
                                        .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
                                        .opacity(0.7)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) { onDelete(dose.medication) } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                        } label: {
                            Text("Completed Doses (\(completedDoses.count))").font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding([.horizontal, .bottom], 16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            
            .onAppear {
                isExpanded = (period == TimePeriod.current && !remainingDoses.isEmpty) || remainingDoses.isEmpty
            }
        }
    }
}


// --- TodayProgressHeader (Final Adherence-Only Bar) ---
struct TodayProgressHeader: View {
    let totalDoses: Int
    let taken: Int
    let Missed: Int
    let remainingCount: Int

    private var takenPercent: Double {
        totalDoses == 0 ? 0 : Double(taken) / Double(totalDoses)
    }
    private var overallProgressText: String {
        totalDoses == 0 ? "0%" : (takenPercent * 100).formatted(.number.precision(.fractionLength(0))) + "%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 1. Progress Bar and Percentage
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text(overallProgressText)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        // Apply the same gradient for the text
                        .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                        .contentTransition(.numericText())
                    Text("Adherence Rate")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Total Doses Count
                VStack(alignment: .trailing) {
                    Text("\(totalDoses)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Total Doses")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Segmented Progress Bar - Adherence Only (Matches Screenshot Visuals)
            AdherenceProgressBar(
                takenPercentage: takenPercent
            )
            .frame(height: 15) // Slightly thicker bar

            // 2. Statistics Row
            HStack {
                // Taken: Using Green icon for universal success
                ProgressStatItem(value: taken, label: "Taken", icon: "checkmark.circle.fill", color: Color.green)
                Spacer()
                // Missed: Using Red icon for universal failure
                ProgressStatItem(value: Missed, label: "Missed", icon: "xmark.circle.fill", color: Color.red)
                Spacer()
                // Remaining
                ProgressStatItem(value: remainingCount, label: "Remaining", icon: "clock.fill", color: .secondary)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// Helper view to draw the segmented progress bar
struct AdherenceProgressBar: View {
    let takenPercentage: Double
    
    // Define the gradient for the 'Taken' segment (Orange to Red)
    let takenGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                
                // Background Track (Empty/Uncompleted Portion)
                Capsule()
                    .fill(Color(.systemGray4))
                    
                // Taken Segment (Gradient) - Overlays the background
                // This bar only shows the percentage of successful doses (Adherence Rate)
                Capsule()
                    .fill(takenPercentage > 0 ? takenGradient : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, geo.size.width * takenPercentage))
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: takenPercentage)
            }
        }
    }
}

// Helper view for a single stat item
struct ProgressStatItem: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
