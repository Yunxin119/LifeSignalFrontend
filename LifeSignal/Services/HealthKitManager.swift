import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    @Published var latestHealthData: HealthData?
    @Published var isAuthorized = false
    
    private init() {}
    
    // Request authorization for health data access
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
        DispatchQueue.main.async {
            self.isAuthorized = true
        }
    }
    
    // Start monitoring health metrics
    func startMonitoring() {
        guard isAuthorized else { return }
        
        // Setup heart rate monitoring
        startHeartRateMonitoring()
        
        // Setup blood oxygen monitoring
        startBloodOxygenMonitoring()
        
        // Setup fall detection
        startFallDetection()
    }
    
    private func startHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func startBloodOxygenMonitoring() {
        guard let bloodOxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: bloodOxygenType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processBloodOxygenSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func startFallDetection() {
        // Note: Fall detection is handled through watchOS app
        // This is a placeholder for future implementation
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        for sample in samples {
            let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            
            if HealthThresholds.isHeartRateAbnormal(heartRate) {
                // Trigger alert for abnormal heart rate
                NotificationCenter.default.post(
                    name: .abnormalHeartRateDetected,
                    object: nil,
                    userInfo: ["heartRate": heartRate]
                )
            }
            
            // Update latest health data
            updateHealthData(heartRate: heartRate)
        }
    }
    
    private func processBloodOxygenSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        for sample in samples {
            let bloodOxygen = sample.quantity.doubleValue(for: HKUnit.percent())
            
            if HealthThresholds.isBloodOxygenAbnormal(bloodOxygen) {
                // Trigger alert for abnormal blood oxygen
                NotificationCenter.default.post(
                    name: .abnormalBloodOxygenDetected,
                    object: nil,
                    userInfo: ["bloodOxygen": bloodOxygen]
                )
            }
            
            // Update latest health data
            updateHealthData(bloodOxygen: bloodOxygen)
        }
    }
    
    private func updateHealthData(heartRate: Double? = nil, bloodOxygen: Double? = nil) {
        DispatchQueue.main.async {
            self.latestHealthData = HealthData(
                heartRate: heartRate ?? self.latestHealthData?.heartRate,
                bloodOxygen: bloodOxygen ?? self.latestHealthData?.bloodOxygen,
                hasFallDetected: self.latestHealthData?.hasFallDetected ?? false,
                location: self.latestHealthData?.location
            )
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let abnormalHeartRateDetected = Notification.Name("abnormalHeartRateDetected")
    static let abnormalBloodOxygenDetected = Notification.Name("abnormalBloodOxygenDetected")
    static let fallDetected = Notification.Name("fallDetected")
    static let emergencyAlertTriggered = Notification.Name("emergencyAlertTriggered")
}

// MARK: - Errors
enum HealthKitError: Error {
    case notAvailable
    case authorizationDenied
} 
