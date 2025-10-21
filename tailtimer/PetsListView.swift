import SwiftUI
import SwiftData

// Main View for the Pets Tab
struct PetsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.name) private var pets: [Pet]

    @State private var isAddingPet = false

    // Add properties for gradient colors, matching Dashboard/Today views
    private let primaryColor = Color.blue
    private let accentColor = Color.orange
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // --- 1. Header with Title and Button (UPDATED) ---
                HStack {
                    Text("My Pets")
                        .font(.largeTitle) // Use large title for the main heading
                        .fontWeight(.bold)
                        // ADDED: Gradient foreground style
                        .foregroundStyle(LinearGradient(
                            colors: [accentColor, primaryColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Spacer() // Pushes button to the right
                    Button {
                        isAddingPet.toggle()
                    } label: {
                        Label("Add Pet", systemImage: "plus.circle.fill") // Use filled circle icon
                            .labelStyle(.iconOnly) // Show only the icon
                            .font(.title) // Make icon larger
                            .foregroundColor(.accentColor) // Use accent color
                    }
                }
                .padding(.horizontal) // Add padding to the header
                .padding(.top) // Add padding above the header

                // --- 2. Pet List or Empty State ---
                if pets.isEmpty {
                    VStack {
                        Spacer(minLength: 50) // Reduced space
                        Image(systemName: "pawprint.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No pets added yet.")
                            .font(.title3)
                            .padding(.top, 8)
                        Text("Tap the '+' button above to add your first pet!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(pets) { pet in
                            NavigationLink(destination: PetProfileView(pet: pet)) {
                                PetListCardView(pet: pet)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deletePet(pet: pet)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            // --- 3. Removed .navigationTitle and .toolbar ---
            .sheet(isPresented: $isAddingPet) {
                AddPetView()
            }
        }
    }

    // Function to delete a single pet (Unchanged)
    private func deletePet(pet: Pet) {
        withAnimation {
            if let medications = pet.medications {
                for med in medications {
                    NotificationManager.shared.removeNotification(for: med)
                }
            }
            modelContext.delete(pet)
        }
    }
}

// --- PetListCardView Helper (REDESIGNED) ---
struct PetListCardView: View {
    let pet: Pet
    
    // Helper for Pet Color (Copied from DashboardView/TodayMedicationRow for consistency)
    private func petColor(for pet: Pet) -> Color {
        let petColors: [Color] = [
            .blue, .cyan, .green, .orange, .pink, .purple, .red, .teal, .indigo, .yellow
        ]
        let hash = abs(pet.name.hashValue)
        return petColors[hash % petColors.count]
    }
    
    private var activeMedCount: Int {
        // Filter active medications by checking if endDate is now or in the future
        pet.medications?.filter { $0.endDate >= Calendar.current.startOfDay(for: .now) }.count ?? 0
    }

    var body: some View {
        HStack(spacing: 16) {
            // --- Pet Avatar / Photo (Updated) ---
            Group {
                if let photoData = pet.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                } else {
                    // Colorful letter-based avatar when no photo is present
                    ZStack {
                        Circle()
                            .fill(petColor(for: pet).opacity(0.15))
                        Text(pet.name.prefix(1).uppercased())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(petColor(for: pet))
                    }
                }
            }
            .frame(width: 65, height: 65) // Slightly larger frame
            .clipShape(Circle())
            
            // --- Pet Info ---
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.title2).fontWeight(.bold).foregroundStyle(.primary)
                Text(pet.breed.isEmpty ? pet.species : "\(pet.species) - \(pet.breed)")
                    .font(.subheadline).foregroundStyle(.secondary)
                
                // Active Medication Badge (Updated)
                if activeMedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "pill.circle.fill")
                            .font(.caption)
                        Text("\(activeMedCount) active medication\(activeMedCount > 1 ? "s" : "")")
                            .font(.caption).fontWeight(.medium)
                    }
                    .foregroundColor(Color.accentColor)
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // --- Disclosure Indicator ---
            Image(systemName: "chevron.right")
                .font(.callout.weight(.medium)).foregroundStyle(.secondary.opacity(0.7))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16) // Increased rounding
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3) // Richer shadow
    }
}

#Preview {
     NavigationStack {
        PetsListView()
            .modelContainer(for: Pet.self, inMemory: true)
     }
}
