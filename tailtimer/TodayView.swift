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
    
    // --- (Computed properties and helper functions) ---
    
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
                        TodayProgressHeader(
                            totalDoses: totalDosesToday,
                            taken: takenCount,
                            Skipped: SkippedCount
                        )
                        .padding(.horizontal)
                        
                        // --- (Rest of the view is unchanged) ---
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
            
            if showToast, let info = toastInfo {
                AnimatedToastView(info: info, isShowing: $showToast)
            }
        }
    }
    
    // --- (Stats & Logic functions) ---
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
    
    private var SkippedCount: Int {
        completedDoses.filter { logFor(dose: $0)?.status == "missed" }.count
    }
    
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
                text: status ? "Marked as Taken!" : "Marked as Skipped",
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

// --- (Enum, TodaySection, TodayProgressHeader, StatItem are unchanged) ---

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

struct TodaySection: View {
    let period: TimePeriod
    let doses: [ScheduledDose]
    let logs: [MedicationLog]
    
    var onMark: (ScheduledDose, Bool) -> Void
    var onEdit: (Medication) -> Void
    var onDelete: (Medication) -> Void
    
    private func logFor(dose: ScheduledDose) -> MedicationLog? {
        // --- UPDATED ---
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
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: period.icon)
                        .font(.title2).foregroundColor(period.color).frame(width: 30)
                    Text(period.rawValue).font(.title2).fontWeight(.bold)
                    Spacer()
                    Text("\(completedDoses.count)/\(doses.count) Completed")
                        .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(remainingDoses) { dose in
                        TodayMedicationRow(dose: dose, log: nil, onMark: onMark, onEdit: onEdit)
                            .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { onDelete(dose.medication) } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                    
                    if !completedDoses.isEmpty {
                        DisclosureGroup(isExpanded: $isExpanded.animation()) {
                            VStack(spacing: 12) {
                                ForEach(completedDoses) { dose in
                                    TodayMedicationRow(dose: dose, log: logFor(dose: dose), onMark: onMark, onEdit: onEdit)
                                        .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) { onDelete(dose.medication) } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                        } label: {
                            Text("Completed").font(.subheadline).fontWeight(.medium).foregroundStyle(.secondary)
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


struct TodayProgressHeader: View {
    let totalDoses: Int
    let taken: Int
    let Skipped: Int

    private var takenPercent: Double {
        totalDoses == 0 ? 0 : Double(taken) / Double(totalDoses)
    }
    private var SkippedPercent: Double {
        totalDoses == 0 ? 0 : Double(Skipped) / Double(totalDoses)
    }
    private var progressText: Double {
        totalDoses == 0 ? 0 : Double(taken) / Double(totalDoses)
    }
    private var remaining: Int {
        totalDoses - taken - Skipped
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(progressText.formatted(.percent.precision(.fractionLength(0))))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Taken")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Color.green
                        .frame(width: geo.size.width * takenPercent)
                    Color.red
                        .frame(width: geo.size.width * SkippedPercent)
                    Color(.systemGray5)
                        .frame(maxWidth: .infinity)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: takenPercent)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: SkippedPercent)
            }
            .frame(height: 10)
            .clipShape(Capsule())
            
            HStack {
                StatItem(value: remaining, label: "Remaining", icon: "list.bullet.clipboard", color: .secondary)
                Spacer()
                StatItem(value: taken, label: "Taken", icon: "checkmark.circle.fill", color: .green)
                Spacer()
                StatItem(value: Skipped, label: "Skipped", icon: "xmark.circle.fill", color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color == .secondary ? .secondary : color)
        }
        .frame(minWidth: 70)
    }
}
