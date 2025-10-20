import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var medications: [Medication]
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]
    
    @State private var medicationToEdit: Medication?
    @State private var visibleSection: TimePeriod? = .none

    // --- Helper: Get all doses for today ---
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
    
    // Helper: Check frequency
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

    // --- Group Doses by Time of Day ---
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
    
    // --- Main Body ---
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    TodayProgressHeader(
                        progress: progress,
                        remaining: remainingCount,
                        taken: takenCount
                    )
                    .padding(.horizontal)
                    
                    // Time-Based Sections
                    TodaySection(
                        period: .morning,
                        doses: doses(for: .morning),
                        logs: logs,
                        onMark: markAsTaken,
                        onEdit: { med in medicationToEdit = med },
                        onDelete: deleteMedication // <-- Pass delete action
                    )
                    
                    TodaySection(
                        period: .afternoon,
                        doses: doses(for: .afternoon),
                        logs: logs,
                        onMark: markAsTaken,
                        onEdit: { med in medicationToEdit = med },
                        onDelete: deleteMedication // <-- Pass delete action
                    )
                    
                    TodaySection(
                        period: .evening,
                        doses: doses(for: .evening),
                        logs: logs,
                        onMark: markAsTaken,
                        onEdit: { med in medicationToEdit = med },
                        onDelete: deleteMedication // <-- Pass delete action
                    )
                    
                    TodaySection(
                        period: .night,
                        doses: doses(for: .night),
                        logs: logs,
                        onMark: markAsTaken,
                        onEdit: { med in medicationToEdit = med },
                        onDelete: deleteMedication // <-- Pass delete action
                    )
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today's Schedule")
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
    }
    
    // --- Stats & Logic ---
    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        let doseScheduledTime = dose.scheduledTimeForToday
        return logs.first { log in
            log.medication?.id == dose.medication.id &&
            log.scheduledTime == doseScheduledTime
        }
    }
    
    private var takenCount: Int {
        scheduledDosesToday.filter { logFor(dose: $0) != nil }.count
    }
    private var remainingCount: Int {
        scheduledDosesToday.filter { logFor(dose: $0) == nil }.count
    }
    private var progress: Double {
        let total = scheduledDosesToday.count
        return total == 0 ? 1.0 : Double(takenCount) / Double(total)
    }
    
    private func markAsTaken(dose: ScheduledDose, status: Bool) {
        withAnimation(.spring) {
            let newStatus = status ? "taken" : "missed"
            let newLog = MedicationLog(
                date: .now,
                status: newStatus,
                scheduledTime: dose.scheduledTimeForToday
            )
            newLog.medication = dose.medication
            modelContext.insert(newLog)
        }
    }
    
    // --- Delete Function ---
    private func deleteMedication(medication: Medication) {
        withAnimation {
            NotificationManager.shared.removeNotification(for: medication)
            modelContext.delete(medication)
        }
    }
}

// --- Enum for Time Periods (No Change) ---
enum TimePeriod: String, CaseIterable {
    // ... (code is identical)
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"
    
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

// --- 1. TodaySection (UPDATED) ---
struct TodaySection: View {
    let period: TimePeriod
    let doses: [ScheduledDose]
    let logs: [MedicationLog]
    
    var onMark: (ScheduledDose, Bool) -> Void
    var onEdit: (Medication) -> Void
    var onDelete: (Medication) -> Void // <-- Added delete closure
    
    // Filter doses for this section
    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        let doseScheduledTime = dose.scheduledTimeForToday
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
            VStack(spacing: 0) {
                // Section Header
                HStack(spacing: 12) {
                    Image(systemName: period.icon)
                        .font(.title2)
                        .foregroundColor(period.color)
                        .frame(width: 30)
                    Text(period.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(completedDoses.count)/\(doses.count) Taken")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Animated Dose List
                VStack(spacing: 12) {
                    // Remaining Doses
                    ForEach(remainingDoses) { dose in
                        TodayMedicationRow(
                            dose: dose,
                            log: nil,
                            onMark: onMark,
                            onEdit: onEdit
                        )
                        .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
                        // --- Swipe to Delete ---
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDelete(dose.medication)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Completed Doses (Collapsible)
                    if !completedDoses.isEmpty {
                        DisclosureGroup(isExpanded: $isExpanded.animation()) {
                            VStack(spacing: 12) {
                                ForEach(completedDoses) { dose in
                                    TodayMedicationRow(
                                        dose: dose,
                                        log: logFor(dose: dose),
                                        onMark: onMark,
                                        onEdit: onEdit
                                    )
                                    .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
                                    // --- Swipe to Delete ---
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            onDelete(dose.medication)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text("Completed")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .onAppear {
                isExpanded = (period == TimePeriod.current && !remainingDoses.isEmpty) || remainingDoses.isEmpty
            }
        }
    }
}

// --- 2. TodayProgressHeader (No Change) ---
struct TodayProgressHeader: View {
    let progress: Double
    let remaining: Int
    let taken: Int
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color(.systemGray5), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                VStack {
                    Text(progress, format: .percent)
                        .font(.title2).fontWeight(.bold)
                    Text("Done").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)
            
            HStack(spacing: 12) {
                // Remaining Stat
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.title2)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("\(remaining)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                Divider()
                Spacer()
                
                // Taken Stat
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("\(taken)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Taken")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
