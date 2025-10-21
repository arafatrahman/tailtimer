import Foundation
import SwiftData

// Represents a single, specific dose of a medication
struct ScheduledDose: Identifiable {
    let id: String
    let medication: Medication
    let time: Date // The time it's scheduled for (e.g., 8:00 AM)
    
    init(medication: Medication, time: Date) {
        self.medication = medication
        self.time = time
        // Create a unique ID for this specific dose time
        self.id = "\(medication.id.uuidString)-\(time.timeIntervalSinceReferenceDate)"
    }
}

// Helper Date Extension
extension Date {
    // Get hour and minute components
    var hourAndMinute: DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: self)
    }
}

// Helper Dose Extension (UPDATED)
extension ScheduledDose {
    // Calculates the exact time for this dose on a specific day
    func scheduledTime(on day: Date) -> Date {
        let components = time.hourAndMinute
        return Calendar.current.date(bySettingHour: components.hour ?? 0,
                                     minute: components.minute ?? 0,
                                     second: 0,
                                     of: day)!
    }
}
