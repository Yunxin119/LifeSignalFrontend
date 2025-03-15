import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var notificationsEnabled = false
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override private init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationsEnabled = granted
                if granted {
                    self?.registerNotificationCategories()
                }
            }
            
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Categories and Actions
    
    private func registerNotificationCategories() {
        // Create actions for emergency alerts
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: .destructive)
        
        let callEmergencyAction = UNNotificationAction(
            identifier: "CALL_EMERGENCY_ACTION",
            title: "Call Emergency Services",
            options: [.foreground])
        
        let checkDetailsAction = UNNotificationAction(
            identifier: "CHECK_DETAILS_ACTION",
            title: "View Details",
            options: [.foreground])
        
        // Create heart rate alert category
        let heartRateCategory = UNNotificationCategory(
            identifier: "HEART_RATE_ALERT",
            actions: [checkDetailsAction, callEmergencyAction, dismissAction],
            intentIdentifiers: [],
            options: [])
        
        // Create blood oxygen alert category
        let bloodOxygenCategory = UNNotificationCategory(
            identifier: "BLOOD_OXYGEN_ALERT",
            actions: [checkDetailsAction, callEmergencyAction, dismissAction],
            intentIdentifiers: [],
            options: [])
        
        // Create fall detected category
        let fallDetectedCategory = UNNotificationCategory(
            identifier: "FALL_DETECTED_ALERT",
            actions: [callEmergencyAction, dismissAction],
            intentIdentifiers: [],
            options: [])
        
        // Register categories
        notificationCenter.setNotificationCategories([
            heartRateCategory,
            bloodOxygenCategory,
            fallDetectedCategory
        ])
    }
    
    // MARK: - Sending Notifications
    
    func sendHeartRateAlert(heartRate: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Abnormal Heart Rate Detected"
        content.body = "Heart rate is \(Int(heartRate)) BPM, which is outside the normal range."
        content.sound = .defaultCritical
        content.categoryIdentifier = "HEART_RATE_ALERT"
        content.userInfo = ["heartRate": heartRate]
        
        // Show immediately
        let request = UNNotificationRequest(
            identifier: "heart-rate-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil)
        
        notificationCenter.add(request)
    }
    
    func sendBloodOxygenAlert(bloodOxygen: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Low Blood Oxygen Level"
        content.body = "Blood oxygen is \(String(format: "%.1f", bloodOxygen))%, which is below the recommended level."
        content.sound = .defaultCritical
        content.categoryIdentifier = "BLOOD_OXYGEN_ALERT"
        content.userInfo = ["bloodOxygen": bloodOxygen]
        
        // Show immediately
        let request = UNNotificationRequest(
            identifier: "blood-oxygen-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil)
        
        notificationCenter.add(request)
    }
    
    func sendFallDetectedAlert(location: HealthData.LocationData? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Fall Detected"
        
        if let location = location {
            content.body = "A fall was detected. Location data is available."
            content.userInfo = [
                "hasFallDetected": true,
                "latitude": location.latitude,
                "longitude": location.longitude
            ]
        } else {
            content.body = "A fall was detected."
            content.userInfo = ["hasFallDetected": true]
        }
        
        content.sound = .defaultCritical
        content.categoryIdentifier = "FALL_DETECTED_ALERT"
        
        // Show immediately
        let request = UNNotificationRequest(
            identifier: "fall-detected-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil)
        
        notificationCenter.add(request)
    }
    
    func sendEmergencyContactAlert(contact: EmergencyContact, healthData: HealthData) {
        let content = UNMutableNotificationContent()
        content.title = "Alert Sent to Emergency Contact"
        content.body = "Emergency alert was sent to \(contact.name)"
        content.sound = .default
        
        // Show immediately
        let request = UNNotificationRequest(
            identifier: "contact-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil)
        
        notificationCenter.add(request)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow notifications to be shown even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification response
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "CALL_EMERGENCY_ACTION":
            // In a real app, we would use callEmergencyServices() here
            print("User chose to call emergency services")
            
        case "CHECK_DETAILS_ACTION":
            // In a real app, we would navigate to health details view
            print("User chose to check details")
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            print("User tapped the notification")
            
        default:
            break
        }
        
        completionHandler()
    }
} 