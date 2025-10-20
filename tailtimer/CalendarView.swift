import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var medications: [Medication]
    @State private var selectedDate: Date = .now
    
    private let petColors: [Color] = [
        .blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow
    ]
    
    private var dosesForSelectedDate: [ScheduledDose] {
        var doses: [ScheduledDose] = []
        let selected = Calendar.current.startOfDay(for: selectedDate)
        
        for med in medications {
            let start = Calendar.current.startOfDay(for: med.startDate)
            let end = Calendar.current.startOfDay(for: med.endDate)
            
            guard selected >= start && selected <= end else { continue }
            
            switch med.frequencyType {
            case "Daily":
                break
            case "Weekly":
                let selectedWeekday = Calendar.current.component(.weekday, from: selected)
                let startWeekday = Calendar.current.component(.weekday, from: start)
                guard selectedWeekday == startWeekday else { continue }
            case "Custom Interval":
                if let interval = med.customInterval {
                    let daysBetween = Calendar.current.dateComponents([.day], from: start, to: selected).day ?? 0
                    guard daysBetween % interval == 0 else { continue }
                } else {
                    continue
                }
            default:
                continue
            }
            
            for time in med.reminderTimes {
                doses.append(ScheduledDose(medication: med, time: time))
            }
        }
        
        return doses.sorted { $0.time < $1.time }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                
                List {
                    Section("Schedule for \(selectedDate.formatted(date: .abbreviated, time: .omitted))") {
                        if dosesForSelectedDate.isEmpty {
                            Text("No medications scheduled for this day.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(dosesForSelectedDate) { dose in
                                CalendarMedRow(dose: dose)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
        }
    }
    
    struct CalendarMedRow: View {
        let dose: ScheduledDose
        
        private let petColors: [Color] = [
            .blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow
        ]
        
        private func petColor(for pet: Pet?) -> Color {
            guard let petName = pet?.name else { return .gray }
            let hash = abs(petName.hashValue)
            return petColors[hash % petColors.count]
        }
        
        var body: some View {
            HStack(spacing: 12) {
                Circle()
                    .fill(petColor(for: dose.medication.pet))
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(dose.medication.name)
                        .font(.headline)
                    Text(dose.medication.pet?.name ?? "Unknown Pet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(dose.time, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 4)
        }
    }
}
