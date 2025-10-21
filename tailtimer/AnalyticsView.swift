import SwiftUI
import SwiftData
import Charts // Import Charts

struct AnalyticsView: View {
    // Queries
    @Query private var pets: [Pet]
    @Query(sort: \MedicationLog.date, order: .reverse) private var logs: [MedicationLog]

    // --- Overall Stats ---
    private var totalTaken: Int { logs.filter { $0.status == "taken" }.count }
    private var totalMissed: Int { logs.filter { $0.status == "missed" }.count }
    private var totalLogged: Int { logs.count }
    private var overallAdherence: Double {
        if totalLogged == 0 { return 0.0 } // Changed default to 0%
        return (Double(totalTaken) / Double(totalLogged)) * 100.0
    }

    // --- Per-Pet Adherence ---
    struct PetAdherenceData: Identifiable {
        let id: UUID
        let name: String
        let adherence: Double
        let color: Color
    }

    private var petAdherenceChartData: [PetAdherenceData] {
        pets.map { pet in
            let petLogs = logs.filter { $0.medication?.pet?.id == pet.id }
            let petTaken = petLogs.filter { $0.status == "taken" }.count
            let petTotal = petLogs.count
            let adherence = (petTotal == 0) ? 0.0 : (Double(petTaken) / Double(petTotal)) * 100.0
            return PetAdherenceData(id: pet.id, name: pet.name, adherence: adherence, color: petColor(for: pet))
        }
        // Sort by adherence, lowest first
        .sorted { $0.adherence < $1.adherence }
    }

    // --- Adherence Trend Data (Last 7 Days) ---
    struct DailyAdherence: Identifiable {
        let id = UUID()
        let date: Date
        let adherence: Double // Percentage (0-100)
    }

    private var last7DaysAdherence: [DailyAdherence] {
        var dailyData: [DailyAdherence] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let logsForDay = logs.filter { log in
                calendar.isDate(log.scheduledTime, inSameDayAs: date)
            }
            let takenOnDay = logsForDay.filter { $0.status == "taken" }.count
            let totalOnDay = logsForDay.count
            let adherence = (totalOnDay == 0) ? 0.0 : (Double(takenOnDay) / Double(totalOnDay)) * 100.0
            dailyData.append(DailyAdherence(date: date, adherence: adherence))
        }
        return dailyData.reversed() // Oldest day first
    }

    // --- Main Body ---
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Overall Adherence Gauge
                Section("Overall Adherence") {
                    VStack(spacing: 20) {
                        AdherenceGauge(percentage: overallAdherence)
                           .frame(height: 120)
                        HStack(spacing: 12) {
                            StatBox(title: "Taken", value: "\(totalTaken)", color: .green)
                            StatBox(title: "Missed", value: "\(totalMissed)", color: .red)
                            StatBox(title: "Total Logged", value: "\(totalLogged)", color: .blue)
                        }
                    }
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())


                // Section 2: Adherence Trend
                Section("Adherence Trend (Last 7 Days)") {
                    if last7DaysAdherence.allSatisfy({ $0.adherence == 0 }) && totalLogged == 0 {
                         Text("Log some doses to see trends here.")
                             .foregroundStyle(.secondary)
                             .frame(maxWidth: .infinity, alignment: .center)
                             .padding(.vertical)
                    } else {
                        Chart(last7DaysAdherence) { dayData in
                            BarMark(
                                x: .value("Date", dayData.date, unit: .day),
                                y: .value("Adherence", dayData.adherence)
                            )
                            .foregroundStyle(adherenceColor(dayData.adherence))
                            .cornerRadius(4)

                            LineMark(
                                x: .value("Date", dayData.date, unit: .day),
                                y: .value("Adherence", dayData.adherence)
                            )
                            .foregroundStyle(.secondary)
                            .interpolationMethod(.catmullRom)
                        }
                        .chartYScale(domain: 0...100)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                            }
                        }
                        .frame(height: 200)
                        .padding(.vertical)
                    }
                }

                // Section 3: Adherence Per Pet
                Section("Adherence By Pet") {
                    if pets.isEmpty {
                        Text("No pets added yet.")
                           .foregroundStyle(.secondary)
                           .frame(maxWidth: .infinity, alignment: .center)
                    } else if petAdherenceChartData.allSatisfy({ $0.adherence == 0 }) && totalLogged == 0 {
                        Text("Log some doses to see adherence here.")
                           .foregroundStyle(.secondary)
                           .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Chart(petAdherenceChartData) { data in
                            BarMark(
                                x: .value("Adherence", data.adherence),
                                y: .value("Pet", data.name)
                            )
                            .foregroundStyle(data.color)
                            .annotation(position: .trailing, alignment: .leading) {
                                Text(String(format: "%.0f%%", data.adherence))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                            }
                        }
                        .chartXScale(domain: 0...100)
                        .frame(height: CGFloat(max(1, petAdherenceChartData.count)) * 40)
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Your Analytics")
        }
    }

    // Helper function for pet color
    private func petColor(for pet: Pet?) -> Color {
        let petColors: [Color] = [.blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow]
        guard let petName = pet?.name else { return .gray }
        let hash = abs(petName.hashValue); return petColors[hash % petColors.count]
    }

    // Helper function for color based on adherence percentage
    private func adherenceColor(_ percentage: Double) -> Color {
        if percentage >= 90 { return .green }
        if percentage >= 70 { return .yellow }
        return .red
    }
}




#Preview {
    AnalyticsView()
        .modelContainer(for: [Pet.self, Medication.self, MedicationLog.self], inMemory: true)
}
