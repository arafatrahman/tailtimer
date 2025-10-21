import SwiftUI
import SwiftData

struct TodayMedicationRow: View {
    let dose: ScheduledDose
    let log: MedicationLog?
    
    // Closures for actions
    var onMark: (ScheduledDose, Bool) -> Void
    var onEdit: (Medication) -> Void
    
    private var status: String { log?.status ?? "pending" }
    private var pet: Pet? { dose.medication.pet }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- 1. Top Info Row (Tappable for Edit) ---
            HStack(spacing: 12) {
                // Color Bar
                Capsule()
                    .fill(petColor(for: pet))
                    .frame(width: 6)
                
                // Pet Photo
                if let photoData = pet?.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: 45, height: 45).clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable().scaledToFit()
                        .frame(width: 45, height: 45).foregroundStyle(.gray.opacity(0.6))
                }
                
                // Dose Info
                VStack(alignment: .leading) {
                    Text(dose.medication.name).font(.headline)
                    Text(pet?.name ?? "Unknown Pet").font(.subheadline).foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Time
                VStack(alignment: .trailing) {
                    Text(dose.time, style: .time)
                        .font(.headline).fontWeight(.bold)
                    Text(dose.medication.dosage)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit(dose.medication) // Tap-to-edit
            }
            
            // --- 2. Action Buttons or Status ---
            if status == "pending" {
                HStack(spacing: 10) {
                    // "Take" Button
                    Button {
                        withAnimation(.spring) {
                            onMark(dose, true) // Mark as taken
                        }
                    } label: {
                        Label("Take", systemImage: "checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    // "Ignore" Button
                    Button {
                        withAnimation(.spring) {
                            onMark(dose, false) // Mark as Missed
                        }
                    } label: {
                        Label("Ignore", systemImage: "xmark")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            } else {
                // Status view (if already taken/Missed)
                HStack {
                    Spacer()
                    if let log = log {
                        Image(systemName: log.status == "taken" ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(log.status == "taken" ? "Taken" : "Missed")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .foregroundStyle(log?.status == "taken" ? .green : .red)
                .padding(8)
                .background((log?.status == "taken" ? Color.green : Color.red).opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        .opacity(status == "pending" ? 1.0 : 0.7)
    }
    
    // Helper for Pet Color
    private func petColor(for pet: Pet?) -> Color {
        let petColors: [Color] = [
            .blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow
        ]
        guard let petName = pet?.name else { return .gray }
        let hash = abs(petName.hashValue)
        return petColors[hash % petColors.count]
    }
}
