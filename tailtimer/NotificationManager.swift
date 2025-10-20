import Foundation
import UserNotifications

class NotificationManager {
    
    // Create a "singleton" instance so we can access it from anywhere
    static let shared = NotificationManager()
    
    // 1. Request Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    // 2. Schedule a Notification
    func scheduleNotification(for medication: Medication) {
        // A. Define the content (what the user sees)
        let content = UNMutableNotificationContent()
        content.title = "Pet Med Reminder 💊"
        // Use the pet's name if available
        let petName = medication.pet?.name ?? "your pet"
        content.body = "It's time for \(petName) to take their \(medication.name) (\(medication.dosage))."
        content.sound = .default
        
        // B. Define the trigger (when it fires)
        // Get the hour and minute from the medication's reminderTime
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: medication.reminderTime)
        
        // Create a trigger that repeats daily at that time
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Note: For this step, we are implementing a DAILY repeating notification.
        // Handling "Weekly" or "Custom Intervals" requires more complex logic to
        // calculate all future dates, which we can add later.
        
        // C. Create the request
        // We use the medication's ID as the identifier. This is CRITICAL
        // so we can find, update, or delete this specific notification later.
        let request = UNNotificationRequest(identifier: medication.id.uuidString, content: content, trigger: trigger)
        
        // D. Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification for \(medication.name)")
            }
        }
    }
    
    // 3. Remove a Scheduled Notification
    func removeNotification(for medication: Medication) {
        let identifier = medication.id.uuidString
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Removed notification for \(medication.name)")
    }
}
