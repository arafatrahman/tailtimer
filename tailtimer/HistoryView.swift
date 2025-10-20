import SwiftUI
import SwiftData

struct HistoryView: View {
    let pet: Pet
    
    // 1. Get all logs from all medications for this pet
    private var allLogs: [MedicationLog] {
        // flatMap merges the arrays of logs from each medication
        // compactMap unwraps the optional history
        let logs = pet.medications?.compactMap { $0.history }.flatMap { $0 } ?? []
        // Sort them by most recent first
        return logs.sorted { $0.date > $1.date }
    }
    
    // 2. Calculate analytics
    private var totalTaken: Int {
        allLogs.filter { $0.status == "taken" }.count
    }
    
    private var totalMissed: Int {
        allLogs.filter { $0.status == "missed" }.count
    }
    
    private var totalDoses: Int {
        allLogs.count
    }
    
    private var adherencePercentage: Double {
        if totalDoses == 0 {
            // No doses logged yet
            return 0.0
        }
        return (Double(totalTaken) / Double(totalDoses)) * 100.0
    }

    var body: some View {
        List {
            // Section 1: Analytics
            Section("Adherence Report") {
                VStack(alignment: .leading, spacing: 10) {
                    // Adherence Percentage Gauge (Modern UI)
                    AdherenceGauge(percentage: adherencePercentage)
                        .frame(height: 150)
                    
                    // Stats
                    HStack(spacing: 12) {
                        StatBox(title: "Taken", value: "\(totalTaken)", color: .green)
                        StatBox(title: "Missed", value: "\(totalMissed)", color: .red)
                        StatBox(title: "Total", value: "\(totalDoses)", color: .blue)
                    }
                }
                .padding(.vertical)
            }
            
            // Section 2: Full History Log
            Section("Full Log") {
                if allLogs.isEmpty {
                    Text("No medication history yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(allLogs) { log in
                        HistoryLogRow(log: log)
                    }
                }
            }
        }
        .navigationTitle("\(pet.name)'s History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// --- Helper Views for the UI ---

// A simple row for the history list
struct HistoryLogRow: View {
    let log: MedicationLog
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: log.status == "taken" ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(log.status == "taken" ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(log.medication?.name ?? "Unknown Medication")
                    .font(.headline)
                Text(log.medication?.dosage ?? "N/A")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(log.date.formatted(date: .numeric, time: .omitted))
                Text(log.date.formatted(date: .omitted, time: .shortened))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// A box for the stats
struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// A gauge for the adherence percentage
struct AdherenceGauge: View {
    let percentage: Double
    
    private var color: Color {
        if percentage >= 80 {
            return .green
        } else if percentage >= 50 {
            return .yellow
        } else if percentage == 0 {
            return Color(.systemGray3) // Neutral for 0%
        } else {
            return .red
        }
    }
    
    private var percentageString: String {
        String(format: "%.0f%%", percentage) // No decimals for cleaner look
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background track
                Circle()
                    .trim(from: 0.3, to: 0.7)
                    .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(.systemGray5))
                    .rotationEffect(.degrees(90))
                
                // Adherence bar
                Circle()
                    .trim(from: 0.3, to: 0.3 + (percentage / 100.0) * 0.4)
                    .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
                    .foregroundColor(color)
                    .rotationEffect(.degrees(90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
                
                // Text in the middle
                VStack {
                    Text(percentageString)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("Adherence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .offset(y: -4)
                }
            }
        }
    }
}
