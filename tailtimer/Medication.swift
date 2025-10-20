import Foundation
import SwiftData

@Model
final class Medication: Codable {
    var id: UUID
    var name: String
    var dosage: String
    var form: String
    var notes: String
    var startDate: Date
    var endDate: Date
    
    // --- THIS IS THE KEY CHANGE ---
    var reminderTimes: [Date] // Was reminderTime: Date
    
    var frequencyType: String
    var customInterval: Int?
    
    var pet: Pet?
    
    @Relationship(deleteRule: .cascade, inverse: \MedicationLog.medication)
    var history: [MedicationLog]? = []
    
    // --- Updated init ---
    init(name: String, dosage: String, form: String, notes: String, startDate: Date, endDate: Date, reminderTimes: [Date], frequencyType: String, customInterval: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.form = form
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.reminderTimes = reminderTimes // Updated
        self.frequencyType = frequencyType
        self.customInterval = customInterval
    }
    
    // --- Updated Codable Conformance ---
    
    enum CodingKeys: String, CodingKey {
        case id, name, dosage, form, notes, startDate, endDate, reminderTimes, frequencyType, customInterval, history
        // We EXCLUDE 'pet'
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.dosage = try container.decode(String.self, forKey: .dosage)
        self.form = try container.decode(String.self, forKey: .form)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.endDate = try container.decode(Date.self, forKey: .endDate)
        self.reminderTimes = try container.decode([Date].self, forKey: .reminderTimes) // Updated
        self.frequencyType = try container.decode(String.self, forKey: .frequencyType)
        self.customInterval = try container.decodeIfPresent(Int.self, forKey: .customInterval)
        self.history = try container.decodeIfPresent([MedicationLog].self, forKey: .history)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(dosage, forKey: .dosage)
        try container.encode(form, forKey: .form)
        try container.encode(notes, forKey: .notes)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(reminderTimes, forKey: .reminderTimes) // Updated
        try container.encode(frequencyType, forKey: .frequencyType)
        try container.encodeIfPresent(customInterval, forKey: .customInterval)
        try container.encodeIfPresent(history, forKey: .history)
    }
}
