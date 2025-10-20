import SwiftUI
import SwiftData

struct PetProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var pet: Pet
    
    @State private var isEditingPet = false
    @State private var isAddingMedication = false
    @State private var isAddingHealthNote = false // New state
    
    // Computed property for sorted medications
    private var sortedMedications: [Medication] {
        pet.medications?.sorted { $0.name < $1.name } ?? []
    }
    
    // Computed property for sorted health notes
    private var sortedHealthNotes: [HealthNote] {
        pet.healthNotes?.sorted { $0.date > $1.date } ?? []
    }
    
    var body: some View {
        List {
            // Section 1: Pet Info Header (Unchanged)
            Section {
                HStack(alignment: .top, spacing: 20) {
                    if let photoData = pet.photo, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } else {
                        Image(systemName: "pawprint.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.gray.opacity(0.4))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pet.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(pet.species)
                            .font(.headline)
                        Text(pet.breed)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("Age: \(pet.age)")
                            Spacer()
                            Text(pet.gender)
                            Spacer()
                        }
                        .font(.caption)
                        .padding(.top, 5)
                    }
                }
                .padding(.vertical)
            }
            
            // Section 2: Medications (Unchanged)
            Section("Medications") {
                if sortedMedications.isEmpty {
                    Text("No medications added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedMedications) { medication in
                        MedicationRowView(medication: medication)
                    }
                    .onDelete(perform: deleteMedication)
                }
                
                Button("Add Medication") {
                    isAddingMedication.toggle()
                }
            }
            
            // Section 3: Health Notes & Appointments (UPDATED)
            Section("Health Notes & Appointments") {
                if sortedHealthNotes.isEmpty {
                    Text("No health notes added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedHealthNotes) { note in
                        HealthNoteRowView(note: note)
                        // We can add a NavigationLink here to a detail view later
                    }
                    .onDelete(perform: deleteHealthNote) // Added delete
                }
                
                Button("Add Health Note") {
                    isAddingHealthNote.toggle() // Updated action
                }
            }
            
            // Section 4: History & Analytics (Unchanged)
            Section("History & Analytics") {
                NavigationLink(destination: HistoryView(pet: pet)) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("View Medication History")
                    }
                }
            }
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditingPet.toggle()
                }
            }
        }
        .sheet(isPresented: $isEditingPet) {
            AddPetView(petToEdit: pet)
        }
        .sheet(isPresented: $isAddingMedication) {
            AddMedicationView(pet: pet)
        }
        // New sheet for adding health notes
        .sheet(isPresented: $isAddingHealthNote) {
            AddHealthNoteView(pet: pet)
        }
    }
    
    // Function to delete a medication (Unchanged)
    private func deleteMedication(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let medication = sortedMedications[index]
                NotificationManager.shared.removeNotification(for: medication)
                pet.medications?.remove(at: index)
                modelContext.delete(medication)
            }
        }
    }
    
    // New function to delete a health note
    private func deleteHealthNote(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let note = sortedHealthNotes[index]
                pet.healthNotes?.remove(at: index)
                modelContext.delete(note)
            }
        }
    }
}
