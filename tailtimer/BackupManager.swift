import Foundation
import SwiftData

// A struct to act as a namespace for our backup logic
struct BackupManager {
    
    // Defines the structure of our backup file
    typealias BackupFormat = [Pet]

    // Error types for better error handling
    enum BackupError: Error {
        case encodingFailed
        case decodingFailed
        case fileReadFailed
    }

    // Encodes the entire database into JSON data
    static func encode(context: ModelContext) throws -> Data {
        // Fetch all Pet objects
        let fetchDescriptor = FetchDescriptor<Pet>()
        let pets = try context.fetch(fetchDescriptor)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // This line will now work
        guard let data = try? encoder.encode(pets) else {
            throw BackupError.encodingFailed
        }
        
        return data
    }
    
    // Decodes JSON data back into Pet objects
    static func decode(from data: Data) throws -> BackupFormat {
        let decoder = JSONDecoder()
        
        // This line will now work
        guard let pets = try? decoder.decode(BackupFormat.self, from: data) else {
            throw BackupError.decodingFailed
        }
        
        return pets
    }

    // --- UPDATED RESTORE FUNCTION ---
    // Restores the database from an array of imported Pets
    // WARNING: This is a destructive operation.
    static func restore(from pets: BackupFormat, context: ModelContext) {
        // 1. Delete all existing data
        do {
            try context.delete(model: Pet.self)
            try context.save()
        } catch {
            print("Failed to delete existing data before restore.")
            return
        }
        
        // 2. Insert and RE-LINK the imported data
        for pet in pets {
            // Insert the pet first
            context.insert(pet)
            
            // Re-link children
            if let medications = pet.medications {
                for med in medications {
                    med.pet = pet // Manually re-link
                    
                    if let history = med.history {
                        for log in history {
                            log.medication = med // Manually re-link
                        }
                    }
                }
            }
            
            if let notes = pet.healthNotes {
                for note in notes {
                    note.pet = pet // Manually re-link
                }
            }
        }
        
        // 3. Save the newly inserted and re-linked data
        do {
            try context.save()
        } catch {
            print("Failed to save restored data: \(error)")
        }
    }
}
