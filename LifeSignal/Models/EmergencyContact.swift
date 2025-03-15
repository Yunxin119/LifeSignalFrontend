import Foundation

struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var relationship: String
    var notificationPreference: NotificationPreference
    var isActive: Bool
    
    enum NotificationPreference: String, Codable, CaseIterable {
        case all = "All Alerts"
        case critical = "Critical Only"
        case none = "None"
    }
    
    init(id: UUID = UUID(),
         name: String,
         phoneNumber: String,
         relationship: String,
         notificationPreference: NotificationPreference = .all,
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
        self.notificationPreference = notificationPreference
        self.isActive = isActive
    }
} 