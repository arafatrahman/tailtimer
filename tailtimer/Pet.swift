import Foundation
import SwiftData

@Model
final class Pet: Codable { // <-- 1. Add Codable
    var id: UUID
    var name: String
    var species: String
    var breed: String
    var age: Int
    var gender: String
    
    @Attribute(.externalStorage)
    var photo: Data?
    
    @Relationship(deleteRule: .cascade, inverse: \Medication.pet)
    var medications: [Medication]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \HealthNote.pet)
    var healthNotes: [HealthNote]? = []
    
    // --- Original init (KEEP THIS) ---
    init(name: String, species: String, breed: String, age: Int, gender: String, photo: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.species = species
        self.breed = breed
        self.age = age
        self.gender = gender
        self.photo = photo
    }
    
    // --- 2. Add Manual Codable Conformance ---
    
    enum CodingKeys: String, CodingKey {
        case id, name, species, breed, age, gender, photo, medications, healthNotes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.species = try container.decode(String.self, forKey: .species)
        self.breed = try container.decode(String.self, forKey: .breed)
        self.age = try container.decode(Int.self, forKey: .age)
        self.gender = try container.decode(String.self, forKey: .gender)
        self.photo = try container.decodeIfPresent(Data.self, forKey: .photo)
        self.medications = try container.decodeIfPresent([Medication].self, forKey: .medications)
        self.healthNotes = try container.decodeIfPresent([HealthNote].self, forKey: .healthNotes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(species, forKey: .species)
        try container.encode(breed, forKey: .breed)
        try container.encode(age, forKey: .age)
        try container.encode(gender, forKey: .gender)
        try container.encodeIfPresent(photo, forKey: .photo)
        try container.encodeIfPresent(medications, forKey: .medications)
        try container.encodeIfPresent(healthNotes, forKey: .healthNotes)
    }
}
