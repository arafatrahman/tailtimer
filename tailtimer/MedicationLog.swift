import Foundation
import SwiftData

@Model
final class MedicationLog: Codable { // <-- 1. Add Codable
    var id: UUID
    var date: Date
    var status: String // Enum: taken, missed
    
    var medication: Medication? // This will NOT be encoded

    // --- Original init (KEEP THIS) ---
    init(date: Date, status: String) {
        self.id = UUID()
        self.date = date
        self.status = status
    }
    
    // --- 2. Add Manual Codable Conformance ---
    
    enum CodingKeys: String, CodingKey {
        case id, date, status
        // We EXCLUDE 'medication'
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.status = try container.decode(String.self, forKey: .status)
        // 'medication' will be nil here and re-linked during restore
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(status, forKey: .status)
        // We EXCLUDE 'medication'
    }
}
