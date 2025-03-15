import Foundation
import HealthKit

struct HealthData: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let heartRate: Double?
    let bloodOxygen: Double?
    let hasFallDetected: Bool
    let location: LocationData?
    
    struct LocationData: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         heartRate: Double? = nil,
         bloodOxygen: Double? = nil,
         hasFallDetected: Bool = false,
         location: LocationData? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.bloodOxygen = bloodOxygen
        self.hasFallDetected = hasFallDetected
        self.location = location
    }
}

// MARK: - Health Thresholds
struct HealthThresholds {
    static let minHeartRate: Double = 40.0
    static let maxHeartRate: Double = 120.0
    static let minBloodOxygen: Double = 95.0
    
    static func isHeartRateAbnormal(_ value: Double) -> Bool {
        return value < minHeartRate || value > maxHeartRate
    }
    
    static func isBloodOxygenAbnormal(_ value: Double) -> Bool {
        return value < minBloodOxygen
    }
} 