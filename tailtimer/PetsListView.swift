import SwiftUI
import SwiftData

// Main View for the Pets Tab
struct PetsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.name) private var pets: [Pet]

    @State private var isAddingPet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                // --- 1. Header with Title and Button ---
                HStack {
                    Text("My Pets")
                        .font(.largeTitle) // Use large title for the main heading
                        .fontWeight(.bold)
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

// --- PetListCardView Helper (Unchanged) ---
struct PetListCardView: View {
    let pet: Pet
    private var activeMedCount: Int {
        pet.medications?.filter { $0.endDate >= .now }.count ?? 0
    }

    var body: some View {
        HStack(spacing: 16) {
            if let photoData = pet.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFill()
                    .frame(width: 60, height: 60).clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .resizable().scaledToFit()
                    .frame(width: 60, height: 60).foregroundStyle(.gray.opacity(0.4))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.title2).fontWeight(.bold).foregroundStyle(.primary)
                Text(pet.breed.isEmpty ? pet.species : "\(pet.species) - \(pet.breed)")
                    .font(.subheadline).foregroundStyle(.secondary)
                if activeMedCount > 0 {
                    Text("\(activeMedCount) active medication\(activeMedCount > 1 ? "s" : "")")
                        .font(.caption).foregroundStyle(Color.accentColor).padding(.top, 2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.callout.weight(.medium)).foregroundStyle(.secondary.opacity(0.7))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
     NavigationStack {
        PetsListView()
            .modelContainer(for: Pet.self, inMemory: true)
     }
}
