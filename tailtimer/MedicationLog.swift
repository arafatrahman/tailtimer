import Foundation
import SwiftData

@Model
final class MedicationLog: Codable {
    var id: UUID
    var date: Date // When the user tapped "Take"
    var status: String
    
    // --- NEW PROPERTY ---
    // The time this dose was scheduled for (e.g., 8:00 AM on Oct 20)
    var scheduledTime: Date
    
    var medication: Medication?

    // --- Updated init ---
    init(date: Date, status: String, scheduledTime: Date) {
        self.id = UUID()
        self.date = date
        self.status = status
        self.scheduledTime = scheduledTime
    }
    
    // --- Updated Codable Conformance ---
    
    enum CodingKeys: String, CodingKey {
        case id, date, status, scheduledTime
        // We EXCLUDE 'medication'
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.status = try container.decode(String.self, forKey: .status)
        self.scheduledTime = try container.decode(Date.self, forKey: .scheduledTime) // Updated
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(status, forKey: .status)
        try container.encode(scheduledTime, forKey: .scheduledTime) // Updated
    }
}
