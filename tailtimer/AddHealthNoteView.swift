import SwiftUI
import SwiftData
import PhotosUI

struct AddHealthNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let pet: Pet
    
    // Form fields
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var date: Date = .now
    
    // Photo Picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Note Details") {
                    TextField("Title (e.g., Vet Visit, Vaccination)", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextEditor(text: $note)
                        .frame(height: 150)
                }
                
                Section("Attach Photo") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 75, height: 75)
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                    .foregroundStyle(.gray.opacity(0.6))
                            }
                            Text(selectedPhotoData == nil ? "Add Photo" : "Change Photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Health Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveNote)
                        .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() {
        // Create the new note
        let newNote = HealthNote(
            title: title,
            note: note,
            date: date,
            photo: selectedPhotoData
        )
        
        // Link it to the pet
        newNote.pet = pet
        pet.healthNotes?.append(newNote)
        
        // Save to database
        modelContext.insert(newNote)
        
        dismiss()
    }
}
