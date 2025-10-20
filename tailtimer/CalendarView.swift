import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var medications: [Medication]
    @State private var selectedDate: Date = .now
    
    // This is the array of predefined colors for pets
    private let petColors: [Color] = [
        .blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow
    ]
    
    // Computed property to find medications for the selected date
    private var medicationsForSelectedDate: [Medication] {
        medications.filter { med in
            // 1. Is it within the start/end date range?
            let selected = Calendar.current.startOfDay(for: selectedDate)
            let start = Calendar.current.startOfDay(for: med.startDate)
            let end = Calendar.current.startOfDay(for: med.endDate)
            
            guard selected >= start && selected <= end else {
                return false
            }
            
            // 2. Is it scheduled for this day based on frequency?
            switch med.frequencyType {
            case "Daily":
                return true
            case "Weekly":
                let selectedWeekday = Calendar.current.component(.weekday, from: selected)
                let startWeekday = Calendar.current.component(.weekday, from: start)
                return selectedWeekday == startWeekday
            case "Custom Interval":
                if let interval = med.customInterval {
                    // Check if the number of days between start and selected is a multiple of the interval
                    let daysBetween = Calendar.current.dateComponents([.day], from: start, to: selected).day ?? 0
                    return daysBetween % interval == 0
                }
                return false
            default:
                return false
            }
        }
        .sorted { $0.reminderTime < $1.reminderTime } // Sort by time
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // The graphical calendar
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                
                // The list of medications for that date
                List {
                    Section("Schedule for \(selectedDate.formatted(date: .abbreviated, time: .omitted))") {
                        if medicationsForSelectedDate.isEmpty {
                            Text("No medications scheduled for this day.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(medicationsForSelectedDate) { med in
                                CalendarMedRow(medication: med)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
        }
    }
    
    // --- Helper Row View ---
    struct CalendarMedRow: View {
        let medication: Medication
        
        // This is the same array as above
        private let petColors: [Color] = [
            .blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow
        ]
        
        // Helper function to get a consistent color for a pet
        private func petColor(for pet: Pet?) -> Color {
            guard let petName = pet?.name else { return .gray }
            let hash = abs(petName.hashValue)
            return petColors[hash % petColors.count]
        }
        
        var body: some View {
            HStack(spacing: 12) {
                // Color-coded circle
                Circle()
                    .fill(petColor(for: medication.pet))
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(.headline)
                    Text(medication.pet?.name ?? "Unknown Pet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(medication.reminderTime, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Pet.self, Medication.self], inMemory: true)
}
