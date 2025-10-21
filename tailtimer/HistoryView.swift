import SwiftUI
import SwiftData

struct HistoryView: View {
    let pet: Pet
    
    // 1. Get all logs
    private var allLogs: [MedicationLog] {
        let logs = pet.medications?.compactMap { $0.history }.flatMap { $0 } ?? []
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
        if totalDoses == 0 { return 0.0 }
        return (Double(totalTaken) / Double(totalDoses)) * 100.0
    }

    var body: some View {
        List {
            // Section 1: Analytics (REDESIGNED)
            Section("Adherence Report") {
                VStack(spacing: 20) { // Increased spacing
                    // Redesigned Gauge
                    AdherenceGauge(percentage: adherencePercentage)
                        .frame(height: 120) // Adjusted height
                    
                    // Redesigned Stat Boxes
                    HStack(spacing: 12) {
                        StatBox(title: "Taken", value: "\(totalTaken)", color: .green)
                        StatBox(title: "Missed", value: "\(totalMissed)", color: .red)
                        StatBox(title: "Total", value: "\(totalDoses)", color: .blue)
                    }
                }
                .padding(.vertical) // Add padding around the whole section
            }
            .listRowBackground(Color.clear) // Make background transparent if needed
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) // Remove default padding
            
            
            // Section 2: Full History Log (Unchanged)
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

// --- Helper Views ---

// HistoryLogRow (Unchanged)
struct HistoryLogRow: View {
    let log: MedicationLog
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: log.status == "taken" ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(log.status == "taken" ? .green : .red)
            VStack(alignment: .leading) {
                Text(log.medication?.name ?? "Unknown Medication").font(.headline)
                Text(log.medication?.dosage ?? "N/A").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(log.scheduledTime.formatted(date: .numeric, time: .omitted))
                Text(log.scheduledTime.formatted(date: .omitted, time: .shortened))
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// --- StatBox (REDESIGNED) ---
struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded)) // Larger font
                .foregroundColor(color) // Use color for text
            Text(title)
                .font(.caption)
                .fontWeight(.medium) // Slightly bolder caption
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16) // More vertical padding
        .background(color.opacity(0.15)) // Slightly stronger background tint
        .cornerRadius(12) // More rounded corners
    }
}

// --- AdherenceGauge (REDESIGNED) ---
struct AdherenceGauge: View {
    let percentage: Double
    
    private var color: Color {
        if percentage >= 80 { return .green }
        if percentage >= 50 { return .yellow }
        if percentage == 0 { return Color(.systemGray3) }
        return .red
    }
    
    private var percentageString: String {
        String(format: "%.0f%%", percentage)
    }
    
    var body: some View {
        ZStack {
            // Background track (thinner, lighter gray)
            Circle()
                .trim(from: 0.25, to: 0.75) // Adjusted arc slightly
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round)) // Thinner line
                .foregroundColor(Color(.systemGray5))
                .rotationEffect(.degrees(90))

            // Adherence bar (thinner)
            Circle()
                .trim(from: 0.25, to: 0.25 + (percentage / 100.0) * 0.5) // Map percentage to arc length
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round)) // Thinner line
                .foregroundColor(color) // Use dynamic color
                .rotationEffect(.degrees(90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)

            // Text in the middle (centered)
            VStack(spacing: 2) { // Reduced spacing
                Text(percentageString)
                    .font(.system(size: 36, weight: .bold, design: .rounded)) // Adjusted font size
                Text("Adherence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            // Removed offset to keep it centered
        }
    }
}
