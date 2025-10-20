import SwiftUI
import SwiftData

struct AddMedicationView: View {
    // Connect to the database and dismiss environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // The pet we're adding medication for
    let pet: Pet
    
    // Form fields
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var form: MedicationForm = .pill
    @State private var notes: String = ""
    @State private var startDate: Date = .now
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var reminderTime: Date = .now
    @State private var frequency: MedicationFrequency = .daily
    @State private var customInterval: Int = 1
    
    // Enums for picker options to make code cleaner and safer
    enum MedicationForm: String, CaseIterable, Identifiable {
        case pill = "Pill"
        case liquid = "Liquid"
        case injection = "Injection"
        case powder = "Powder"
        case other = "Other"
        var id: Self { self }
    }
    
    enum MedicationFrequency: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        case custom = "Custom Interval"
        var id: Self { self }
    }
    
    // Formatter for custom interval (numbers only)
    var intervalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 1
        return formatter
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Medication Name (e.g., Apoquel)", text: $name)
                    TextField("Dosage (e.g., 1 tablet, 5ml)", text: $dosage)
                    Picker("Form", selection: $form) {
                        ForEach(MedicationForm.allCases) { form in
                            Text(form.rawValue).tag(form)
                        }
                    }
                }
                
                Section("Schedule & Frequency") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(MedicationFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    // Show this field only if frequency is "Custom"
                    if frequency == .custom {
                        HStack {
                            TextField("Every", value: $customInterval, formatter: intervalFormatter)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text("day(s)")
                        }
                    }
                }
                
                Section("Reminder") {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveMedication)
                        .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
    
    private func saveMedication() {
        // Create the new medication object
        let newMedication = Medication(
            name: name,
            dosage: dosage,
            form: form.rawValue,
            notes: notes,
            startDate: startDate,
            endDate: endDate,
            reminderTime: reminderTime,
            frequencyType: frequency.rawValue,
            customInterval: frequency == .custom ? customInterval : nil
        )
        
        // Link it to the pet
        newMedication.pet = pet
        
        // Add it to the pet's medication list (this ensures the relationship is saved)
        pet.medications?.append(newMedication)
        
        // Insert into the database
        modelContext.insert(newMedication)
        
        // Schedule the notification
        NotificationManager.shared.scheduleNotification(for: newMedication)
        
        dismiss()
    }
}

#Preview {
    // This preview requires a bit more setup since it needs a Pet
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let samplePet = Pet(name: "Preview Pet", species: "Cat", breed: "Siamese", age: 2, gender: "Female")
    
    return AddMedicationView(pet: samplePet)
        .modelContainer(container)
}
