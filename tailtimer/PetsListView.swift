import SwiftUI
import SwiftData

// Renamed from HomeView to PetsListView
struct PetsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pet.name) private var pets: [Pet]

    @State private var isAddingPet = false

    var body: some View {
        // This view now gets its own NavigationStack for the "Pets" tab
        NavigationStack {
            List {
                Section("My Pets") {
                    if pets.isEmpty {
                        Text("No pets added yet. Tap the '+' button to add your first pet!")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    ForEach(pets) { pet in
                        NavigationLink(destination: PetProfileView(pet: pet)) {
                            PetRowView(pet: pet)
                        }
                    }
                    .onDelete(perform: deletePets)
                }
            }
            .navigationTitle("My Pets") // Title for this tab's screen
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingPet.toggle()
                    } label: {
                        Label("Add Pet", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingPet) {
                AddPetView()
            }
            // We removed the .onAppear notification request
            // It's now in MainTabView.swift
        }
    }
    
    private func deletePets(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let pet = pets[index]
                
                if let medications = pet.medications {
                    for med in medications {
                        NotificationManager.shared.removeNotification(for: med)
                    }
                }
                modelContext.delete(pet)
            }
        }
    }
}

// PetRowView remains the same, it can stay in this file or its own
struct PetRowView: View {
    let pet: Pet
    
    var body: some View {
        HStack {
            if let photoData = pet.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.gray.opacity(0.6))
            }
            
            VStack(alignment: .leading) {
                Text(pet.name)
                    .font(.headline)
                Text(pet.species)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PetsListView()
        .modelContainer(for: Pet.self, inMemory: true)
}
