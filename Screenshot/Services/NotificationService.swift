//
//  NotificationService.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import Foundation
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission Management
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized
                completion(isAuthorized)
            }
        }
    }
    
    // MARK: - Simple Notification Scheduling
    func scheduleTestNotification() {
        // Cancel any existing test notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["test_notification"])
        
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from Screenshot Organizer"
        content.sound = .default
        content.badge = 1
        
        // Schedule for 2 seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule test notification: \(error.localizedDescription)")
            } else {
                print("✅ Test notification scheduled for 2 seconds")
            }
        }
    }
    
    func scheduleScreenshotReminder(for screenshot: Screenshot, after hours: Double = 24.0) {
        let content = UNMutableNotificationContent()
        content.title = "Screenshot Reminder"
        content.body = "Don't forget to organize your screenshot: \(screenshot.fileName)"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: hours * 3600, repeats: false)
        let identifier = "screenshot_reminder_\(screenshot.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule screenshot reminder: \(error.localizedDescription)")
            } else {
                print("✅ Screenshot reminder scheduled for \(hours) hours")
            }
        }
    }
    
    func cancelScreenshotReminder(for screenshot: Screenshot) {
        let identifier = "screenshot_reminder_\(screenshot.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ Cancelled reminder for screenshot: \(screenshot.fileName)")
    }
    
    // MARK: - Debugging
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✅ Cleared all pending notifications")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        print("📱 User tapped notification: \(response.notification.request.identifier)")
        completionHandler()
    }
}