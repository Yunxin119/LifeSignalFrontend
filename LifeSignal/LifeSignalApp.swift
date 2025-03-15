//
//  LifeSignalApp.swift
//  LifeSignal
//
//  Created by Yunxin Liu on 3/8/25.
//
import SwiftUI
import UserNotifications

@main
struct LifeSignalApp: App {
    // Initialize managers
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        // Register for notifications when app starts
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
        
        // Listen for health data anomalies
        setupAnomalyNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(notificationManager)
        }
    }
    
    private func setupAnomalyNotifications() {
        // Listen for heart rate anomalies
        NotificationCenter.default.addObserver(
            forName: .abnormalHeartRateDetected,
            object: nil,
            queue: .main
        ) { notification in
            if let heartRate = notification.userInfo?["heartRate"] as? Double {
                notificationManager.sendHeartRateAlert(heartRate: heartRate)
            }
        }
        
        // Listen for blood oxygen anomalies
        NotificationCenter.default.addObserver(
            forName: .abnormalBloodOxygenDetected,
            object: nil,
            queue: .main
        ) { notification in
            if let bloodOxygen = notification.userInfo?["bloodOxygen"] as? Double {
                notificationManager.sendBloodOxygenAlert(bloodOxygen: bloodOxygen)
            }
        }
        
        // Listen for fall detection
        NotificationCenter.default.addObserver(
            forName: .fallDetected,
            object: nil,
            queue: .main
        ) { notification in
            if let healthData = notification.userInfo?["healthData"] as? HealthData {
                notificationManager.sendFallDetectedAlert(location: healthData.location)
            } else {
                notificationManager.sendFallDetectedAlert()
            }
        }
        
        // Listen for emergency alerts triggered
        NotificationCenter.default.addObserver(
            forName: .emergencyAlertTriggered,
            object: nil,
            queue: .main
        ) { notification in
            if let healthData = notification.userInfo?["healthData"] as? HealthData {
                // Here we would normally notify emergency contacts
                // For this example, we'll just show a local notification
                handleEmergencyAlert(healthData)
            }
        }
    }
    
    private func handleEmergencyAlert(_ healthData: HealthData) {
        // MARK: In a real app, this would fetch contacts and send alerts
        // For now, just show a notification
        let dummyContact = EmergencyContact(
            name: "Emergency Contact",
            phoneNumber: "911",
            relationship: "Emergency Services",
            notificationPreference: .all
        )
        
        notificationManager.sendEmergencyContactAlert(contact: dummyContact, healthData: healthData)
    }
}
