import Foundation
import Contacts
import MessageUI

class EmergencyContactManager: ObservableObject {
    static let shared = EmergencyContactManager()
    
    @Published var contacts: [EmergencyContact] = []
    private let userDefaults = UserDefaults.standard
    private let contactsKey = "emergencyContacts"
    
    private init() {
        loadContacts()
    }
    
    // MARK: - Contact Management
    
    func addContact(_ contact: EmergencyContact) {
        contacts.append(contact)
        saveContacts()
    }
    
    func updateContact(_ contact: EmergencyContact) {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index] = contact
            saveContacts()
        }
    }
    
    func removeContact(_ contact: EmergencyContact) {
        contacts.removeAll { $0.id == contact.id }
        saveContacts()
    }
    
    func toggleContactActive(_ contact: EmergencyContact) {
        if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
            contacts[index].isActive.toggle()
            saveContacts()
        }
    }
    
    // MARK: - Emergency Alert Handling
    
    func handleEmergencyAlert(_ healthData: HealthData) {
        let activeContacts = contacts.filter { $0.isActive }
        
        for contact in activeContacts {
            switch contact.notificationPreference {
            case .all:
                sendEmergencyAlert(to: contact, with: healthData)
            case .critical:
                if isHealthDataCritical(healthData) {
                    sendEmergencyAlert(to: contact, with: healthData)
                }
            case .none:
                break
            }
        }
    }
    
    private func isHealthDataCritical(_ healthData: HealthData) -> Bool {
        if let heartRate = healthData.heartRate {
            if HealthThresholds.isHeartRateAbnormal(heartRate) {
                return true
            }
        }
        
        if let bloodOxygen = healthData.bloodOxygen {
            if HealthThresholds.isBloodOxygenAbnormal(bloodOxygen) {
                return true
            }
        }
        
        return healthData.hasFallDetected
    }
    
    private func sendEmergencyAlert(to contact: EmergencyContact, with healthData: HealthData) {
        let message = createEmergencyMessage(for: healthData)
        
        // Send SMS
        if MFMessageComposeViewController.canSendText() {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sendEmergencySMS,
                    object: nil,
                    userInfo: [
                        "phoneNumber": contact.phoneNumber,
                        "message": message
                    ]
                )
            }
        }
        
        // Log the alert
        logEmergencyAlert(contact: contact, healthData: healthData)
    }
    
    private func createEmergencyMessage(for healthData: HealthData) -> String {
        var message = "EMERGENCY ALERT from LifeSignal\n\n"
        
        if let heartRate = healthData.heartRate {
            message += "Heart Rate: \(Int(heartRate)) BPM\n"
        }
        
        if let bloodOxygen = healthData.bloodOxygen {
            message += "Blood Oxygen: \(String(format: "%.1f", bloodOxygen))%\n"
        }
        
        if healthData.hasFallDetected {
            message += "Fall Detected!\n"
        }
        
        if let location = healthData.location {
            message += "\nLocation: https://maps.google.com/?q=\(location.latitude),\(location.longitude)"
        }
        
        return message
    }
    
    // MARK: - Persistence
    
    private func saveContacts() {
        if let encoded = try? JSONEncoder().encode(contacts) {
            userDefaults.set(encoded, forKey: contactsKey)
        }
    }
    
    private func loadContacts() {
        if let data = userDefaults.data(forKey: contactsKey),
           let decoded = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
            contacts = decoded
        }
    }
    
    private func logEmergencyAlert(contact: EmergencyContact, healthData: HealthData) {
        // TODO: Implement alert logging
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let sendEmergencySMS = Notification.Name("sendEmergencySMS")
} 