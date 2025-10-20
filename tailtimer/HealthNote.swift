import Foundation
import SwiftData

@Model
final class HealthNote: Codable { // <-- 1. Add Codable
    var id: UUID
    var title: String
    var note: String
    var date: Date
    @Attribute(.externalStorage)
    var photo: Data?
    
    var pet: Pet? // This will NOT be encoded

    // --- Original init (KEEP THIS) ---
    init(title: String, note: String, date: Date, photo: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.date = date
        self.photo = photo
    }
    
    // --- 2. Add Manual Codable Conformance ---
    
    enum CodingKeys: String, CodingKey {
        case id, title, note, date, photo
        // We EXCLUDE 'pet'
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.note = try container.decode(String.self, forKey: .note)
        self.date = try container.decode(Date.self, forKey: .date)
        self.photo = try container.decodeIfPresent(Data.self, forKey: .photo)
        // 'pet' will be nil here and re-linked during restore
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(note, forKey: .note)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(photo, forKey: .photo)
        // We EXCLUDE 'pet'
    }
}
