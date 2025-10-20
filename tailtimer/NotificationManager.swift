import Foundation
import UserNotifications

class NotificationManager {
    
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    // --- UPDATED: Schedule Function ---
    func scheduleNotification(for medication: Medication) {
        // First, remove all old notifications for this med
        removeNotification(for: medication)
        
        let petName = medication.pet?.name ?? "your pet"
        
        // --- THIS IS THE FIX ---
        // Create a formatter to use inside the print statement
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        // Loop through each time and create a separate notification
        for time in medication.reminderTimes {
            let content = UNMutableNotificationContent()
            content.title = "Pet Med Reminder 💊"
            content.body = "It's time for \(petName) to take their \(medication.name) (\(medication.dosage))."
            content.sound = .default
            
            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // --- Create a UNIQUE identifier ---
            // Format: "MedicationID-TimeInSeconds"
            let timeInterval = time.timeIntervalSinceReferenceDate
            let identifier = "\(medication.id.uuidString)-\(timeInterval)"
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    // --- Use the formatter here ---
                    print("Successfully scheduled notification for \(medication.name) at \(formatter.string(from: time))")
                }
            }
        }
    }
    
    // --- UPDATED: Remove Function ---
    func removeNotification(for medication: Medication) {
        // We must build the same unique identifiers to remove them
        var identifiers: [String] = []
        for time in medication.reminderTimes {
            let timeInterval = time.timeIntervalSinceReferenceDate
            let identifier = "\(medication.id.uuidString)-\(timeInterval)"
            identifiers.append(identifier)
        }
        
        if identifiers.isEmpty { return }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Removed \(identifiers.count) notifications for \(medication.name)")
    }
}
