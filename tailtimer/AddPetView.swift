import SwiftUI
import SwiftData
import PhotosUI // We need this for the Photo Picker

struct AddPetView: View {
    // Connect to the database
    @Environment(\.modelContext) private var modelContext
    // Allow the view to be closed
    @Environment(\.dismiss) private var dismiss
    
    // This will hold the pet we are editing, if any
    var petToEdit: Pet?
    
    // Form fields
    @State private var name: String = ""
    @State private var species: String = ""
    @State private var breed: String = ""
    @State private var age: Int = 0
    @State private var gender: String = "Male" // Default value
    
    // Photo Picker state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    private let genders = ["Male", "Female", "Other"]
    
    // Custom title for the screen
    var formTitle: String {
        petToEdit == nil ? "Add New Pet" : "Edit Pet"
    }
    
    // Formatter to allow only numbers for age
    var ageFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = 99
        return formatter
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet Photo") {
                    // Photo Picker UI
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 75, height: 75)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "pawprint.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                    .foregroundStyle(.gray.opacity(0.6))
                            }
                            Text(selectedPhotoData == nil ? "Add Photo" : "Change Photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        // Asynchronously load the photo data when the user picks one
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                            }
                        }
                    }
                }
                
                Section("Pet Details") {
                    TextField("Name", text: $name)
                    TextField("Species (e.g., Dog, Cat)", text: $species)
                    TextField("Breed", text: $breed)
                    
                    // Age
                    TextField("Age", value: $age, formatter: ageFormatter)
                        .keyboardType(.numberPad)
                    
                    // Gender
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel Button
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                // Save Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: savePet)
                        // Don't let the user save if the name is blank
                        .disabled(name.isEmpty)
                }
            }
            // This runs when the view first appears
            .onAppear {
                // If we are editing a pet, fill in the form fields
                if let pet = petToEdit {
                    name = pet.name
                    species = pet.species
                    breed = pet.breed
                    age = pet.age
                    gender = pet.gender
                    selectedPhotoData = pet.photo
                }
            }
        }
    }
    
    // Function to save or update the pet
    private func savePet() {
        withAnimation {
            if let pet = petToEdit {
                // We are editing, so update the existing pet's properties
                pet.name = name
                pet.species = species
                pet.breed = breed
                pet.age = age
                pet.gender = gender
                pet.photo = selectedPhotoData
            } else {
                // We are adding, so create a new pet object
                let newPet = Pet(
                    name: name,
                    species: species,
                    breed: breed,
                    age: age,
                    gender: gender,
                    photo: selectedPhotoData
                )
                // Insert the new pet into the database
                modelContext.insert(newPet)
            }
        }
        // Close the sheet
        dismiss()
    }
}
