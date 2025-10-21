import Foundation
import UserNotifications
import SwiftData

class NotificationManager {
    
    static let shared = NotificationManager()
    
    // Helper to get persistent notification settings
    private static var isSoundEnabled: Bool {
        // Reads from AppStorage (which uses UserDefaults)
        // Must match the key used in SettingsView.swift
        UserDefaults.standard.bool(forKey: "isSoundEnabled")
    }
    
    // Gets the current snooze duration saved by the SettingsView
    private static var currentSnoozeDuration: Int {
        // Reads from AppStorage. Default to 5 min.
        UserDefaults.standard.integer(forKey: "snoozeDuration") > 0
            ? UserDefaults.standard.integer(forKey: "snoozeDuration")
            : 5
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted { print("Notification permission granted.") }
            else if let error = error { print(error.localizedDescription) }
        }
    }
    
    // Schedules all times for a given medication
    func scheduleNotification(for medication: Medication) {
        removeNotification(for: medication)
        
        let petName = medication.pet?.name ?? "your pet"
        let soundPreference: UNNotificationSound? = NotificationManager.isSoundEnabled ? .default : .none
        
        // Loop through each time
        for time in medication.reminderTimes {
            let content = UNMutableNotificationContent()
            content.title = "Pet Med Reminder 💊"
            content.body = "It's time for \(petName) to take their \(medication.name) (\(medication.dosage))."
            content.sound = soundPreference // Apply sound preference
            
            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Create a UNIQUE identifier
            let timeInterval = time.timeIntervalSinceReferenceDate
            let identifier = "\(medication.id.uuidString)-\(timeInterval)"
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error { print("Error scheduling notification: \(error.localizedDescription)") }
            }
        }
    }
    
    // Removes all notifications for a given medication
    func removeNotification(for medication: Medication) {
        var identifiers: [String] = []
        for time in medication.reminderTimes {
            let timeInterval = time.timeIntervalSinceReferenceDate
            let identifier = "\(medication.id.uuidString)-\(timeInterval)"
            identifiers.append(identifier)
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // Schedules a single notification to fire after the snooze duration
    func scheduleSnooze(for medication: Medication) {
        let duration = NotificationManager.currentSnoozeDuration
        
        let content = UNMutableNotificationContent()
        content.title = "SNOOZE: \(medication.name)"
        content.body = "Time for \(medication.pet?.name ?? "your pet")'s dose."
        content.sound = .default // Use default sound for snooze urgency

        // Trigger to fire once after the snooze interval
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(duration * 60), repeats: false)
        
        let snoozeIdentifier = "\(medication.id.uuidString)-SNOOZE-\(UUID().uuidString)"
        
        let request = UNNotificationRequest(identifier: snoozeIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Error scheduling snooze: \(error.localizedDescription)") }
            else { print("Snooze scheduled for \(duration) minutes.") }
        }
    }
    
    // NOTE: This function is required if the sound setting is changed mid-session.
    // It would need access to the ModelContext, typically passed from the caller.
    /*
    func rescheduleAll(context: ModelContext) {
        do {
            let fetchDescriptor = FetchDescriptor<Medication>()
            let allMeds = try context.fetch(fetchDescriptor)
            
            // Clear all pending notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            // Reschedule all medications with the new sound setting
            for med in allMeds {
                scheduleNotification(for: med)
            }
        } catch {
            print("Failed to reschedule all notifications: \(error)")
        }
    }
    */
}
