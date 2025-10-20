import SwiftUI
import SwiftData

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let pet: Pet
    var medicationToEdit: Medication?
    
    // Form fields
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var form: MedicationForm = .pill
    @State private var notes: String = ""
    @State private var startDate: Date = .now
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    
    // Reminder Times
    @State private var reminderTimes: [Date] = []
    @State private var newReminderTime: Date = .now
    
    @State private var frequency: MedicationFrequency = .daily
    @State private var customInterval: Int = 1
    
    // Enums
    enum MedicationForm: String, CaseIterable, Identifiable {
        case pill = "Pill", liquid = "Liquid", injection = "Injection", powder = "Powder", other = "Other"
        var id: Self { self }
    }
    enum MedicationFrequency: String, CaseIterable, Identifiable {
        case daily = "Daily", weekly = "Weekly", custom = "Custom Interval"
        var id: Self { self }
    }
    
    var intervalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 1
        return formatter
    }
    
    var formTitle: String {
        medicationToEdit == nil ? "Add Medication" : "Edit Medication"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Medication Name", text: $name)
                    TextField("Dosage", text: $dosage)
                    
                    // --- THIS IS THE FIX ---
                    Picker("Form", selection: $form) {
                        ForEach(MedicationForm.allCases) { form in
                            Text(form.rawValue).tag(form)
                        }
                    }
                }
                
                Section("Schedule & Frequency") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    
                    // --- THIS IS THE SECOND FIX ---
                    Picker("Frequency", selection: $frequency) {
                        ForEach(MedicationFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    if frequency == .custom {
                        HStack {
                            TextField("Every", value: $customInterval, formatter: intervalFormatter)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text("day(s)")
                        }
                    }
                }
                
                // Reminder Section (no change)
                Section("Reminder Times") {
                    if reminderTimes.isEmpty {
                        Text("Add at least one reminder time.")
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(reminderTimes, id: \.self) { time in
                        Text(time, style: .time)
                    }
                    .onDelete(perform: deleteTime)
                    
                    HStack {
                        DatePicker("Add Time", selection: $newReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Spacer()
                        Button("Add", action: addTime)
                            .buttonStyle(.bordered)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveMedication)
                        .disabled(name.isEmpty || dosage.isEmpty || reminderTimes.isEmpty)
                }
            }
            .onAppear {
                if let med = medicationToEdit {
                    // Load existing data
                    name = med.name
                    dosage = med.dosage
                    form = MedicationForm(rawValue: med.form) ?? .pill
                    notes = med.notes
                    startDate = med.startDate
                    endDate = med.endDate
                    reminderTimes = med.reminderTimes
                    frequency = MedicationFrequency(rawValue: med.frequencyType) ?? .daily
                    customInterval = med.customInterval ?? 1
                }
            }
        }
    }
    
    private func addTime() {
        if !reminderTimes.contains(where: { Calendar.current.isDate($0, equalTo: newReminderTime, toGranularity: .minute) }) {
            reminderTimes.append(newReminderTime)
            reminderTimes.sort()
        }
    }
    
    private func deleteTime(at offsets: IndexSet) {
        reminderTimes.remove(atOffsets: offsets)
    }
    
    private func saveMedication() {
        if let med = medicationToEdit {
            // Update existing
            med.name = name
            med.dosage = dosage
            med.form = form.rawValue
            med.notes = notes
            med.startDate = startDate
            med.endDate = endDate
            med.reminderTimes = reminderTimes
            med.frequencyType = frequency.rawValue
            med.customInterval = frequency == .custom ? customInterval : nil
            
            NotificationManager.shared.scheduleNotification(for: med)
            
        } else {
            // Create new
            let newMedication = Medication(
                name: name,
                dosage: dosage,
                form: form.rawValue,
                notes: notes,
                startDate: startDate,
                endDate: endDate,
                reminderTimes: reminderTimes,
                frequencyType: frequency.rawValue,
                customInterval: frequency == .custom ? customInterval : nil
            )
            
            newMedication.pet = pet
            pet.medications?.append(newMedication)
            modelContext.insert(newMedication)
            
            NotificationManager.shared.scheduleNotification(for: newMedication)
        }
        
        dismiss()
    }
}
