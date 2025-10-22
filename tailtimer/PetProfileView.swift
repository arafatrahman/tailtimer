import SwiftUI
import SwiftData

struct PetProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // Used to close the view after deletion
    @Bindable var pet: Pet
    
    @State private var isEditingPet = false
    @State private var isAddingMedication = false
    @State private var isAddingHealthNote = false
    @State private var medicationToEdit: Medication?
    // ADDED: State for delete confirmation
    @State private var showDeleteConfirmation = false
    
    // Computed properties for sorted data
    private var sortedMedications: [Medication] {
        // Ensure this list is always safe, even if pet.medications is nil
        pet.medications?.sorted { $0.name < $1.name } ?? []
    }
    private var sortedHealthNotes: [HealthNote] {
        pet.healthNotes?.sorted { $0.date > $1.date } ?? []
    }

    // Function to handle pet deletion and navigation
    private func deletePetAndDismiss() {
        // 1. Manually remove notifications (crucial before deletion)
        if let medications = pet.medications {
            for med in medications {
                NotificationManager.shared.removeNotification(for: med)
            }
        }
        
        // 2. Delete the pet (cascade handles records)
        modelContext.delete(pet)
        
        // 3. Dismiss the profile view
        dismiss()
    }
    
    var body: some View {
        List {
            // --- Section 1: Redesigned Profile Header ---
            Section {
                VStack(spacing: 16) {
                    // Pet Photo
                    if let photoData = pet.photo, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 2))
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: "pawprint.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(.gray.opacity(0.4))
                    }
                    
                    // Pet Name
                    Text(pet.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Pet Stats Bubbles
                    HStack(spacing: 10) {
                        PetStatBubble(label: "Age", value: "\(pet.age)")
                        PetStatBubble(label: "Species", value: pet.species)
                        PetStatBubble(label: "Gender", value: pet.gender)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.systemGroupedBackground))
            
            // --- Section 2: Medications ---
            Section("Medications") {
                if sortedMedications.isEmpty {
                    Text("No medications added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedMedications) { medication in
                        Button {
                            medicationToEdit = medication // Set the med to edit on tap
                        } label: {
                            MedicationRowView(medication: medication)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading) {
                            Button {
                                medicationToEdit = medication
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: deleteMedication)
                }
                
                Button("Add Medication") {
                    isAddingMedication.toggle()
                }
            }
            
            // --- Section 3: Health Notes ---
            Section("Health Notes & Appointments") {
                if sortedHealthNotes.isEmpty {
                    Text("No health notes added yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedHealthNotes) { note in
                        HealthNoteRowView(note: note)
                    }
                    .onDelete(perform: deleteHealthNote)
                }
                
                Button("Add Health Note") {
                    isAddingHealthNote.toggle()
                }
            }
            
            // --- Section 4: History ---
            Section("History & Analytics") {
                NavigationLink(destination: HistoryView(pet: pet)) {
                    Label("View Medication History", systemImage: "chart.bar.xaxis")
                }
            }
            
            // --- Section 5: Delete Pet (NEW) ---
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete \(pet.name)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit Pet") {
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
        .sheet(item: $medicationToEdit) { med in // This sheet handles the edit
            AddMedicationView(pet: pet, medicationToEdit: med)
        }
        .sheet(isPresented: $isAddingHealthNote) {
            AddHealthNoteView(pet: pet)
        }
        // ADDED: Confirmation Alert for Pet Deletion
        .alert("Delete Pet?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: deletePetAndDismiss)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(pet.name)? This action is permanent and will remove all associated medications and records.")
        }
    }
    
    // --- Delete Functions (FIXED to prevent crash on deleting last item) ---
    private func deleteMedication(offsets: IndexSet) {
        withAnimation {
            // Find the medications to delete using the sorted array
            let medicationsToDelete = offsets.map { sortedMedications[$0] }

            for medication in medicationsToDelete {
                // 1. Remove associated notifications
                NotificationManager.shared.removeNotification(for: medication)
                
                // 2. Safely remove the medication from the pet's list
                if let index = pet.medications?.firstIndex(where: { $0.id == medication.id }) {
                    pet.medications?.remove(at: index)
                }

                // 3. Delete the medication object from the database context
                modelContext.delete(medication)
            }
        }
    }
    
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


// --- Helper View: PetStatBubble (No Change) ---
struct PetStatBubble: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 80, minHeight: 40)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
