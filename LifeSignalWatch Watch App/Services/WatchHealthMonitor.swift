import Foundation
import HealthKit
import WatchKit

class WatchHealthMonitor: ObservableObject {
    static let shared = WatchHealthMonitor()
    private let healthStore = HKHealthStore()
    // 移除 workoutSession，因为 WKWorkoutSession 已被废弃
    
    @Published var currentHeartRate: Double?
    @Published var currentBloodOxygen: Double?
    @Published var isHeartRateAbnormal = false
    @Published var isBloodOxygenAbnormal = false
    
    private init() {}
    
    func startMonitoring() {
        requestAuthorization()
        startHeartRateMonitoring()
        startBloodOxygenMonitoring()
        startFallDetection()
    }
    
    private func requestAuthorization() {
        let typesToRead: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        ]
        
        healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead) { success, error in
            if !success {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }
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
        
        query.updateHandler = { [weak self] query, samples, deleted, anchor, error in
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
        
        query.updateHandler = { [weak self] query, samples, deleted, anchor, error in
            self?.processBloodOxygenSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func startFallDetection() {
        if #available(watchOS 9.0, *) {
            // MARK: THIS SHOULD BE CHANGED TO API FALL DETECTION LOGIC (MAYBE)
            print("Fall detection capability check - available on newer devices")
        }
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            if let latestSample = samples.last {
                let heartRate = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                self.currentHeartRate = heartRate
                self.isHeartRateAbnormal = HealthThresholds.isHeartRateAbnormal(heartRate)
                
                if self.isHeartRateAbnormal {
                    self.notifyAbnormalHeartRate(heartRate)
                }
            }
        }
    }
    
    private func processBloodOxygenSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            if let latestSample = samples.last {
                let bloodOxygen = latestSample.quantity.doubleValue(for: HKUnit.percent())
                self.currentBloodOxygen = bloodOxygen
                self.isBloodOxygenAbnormal = HealthThresholds.isBloodOxygenAbnormal(bloodOxygen)
                
                if self.isBloodOxygenAbnormal {
                    self.notifyAbnormalBloodOxygen(bloodOxygen)
                }
            }
        }
    }
    
    func triggerEmergencyAlert() {
        let healthData = HealthData(
            heartRate: currentHeartRate,
            bloodOxygen: currentBloodOxygen,
            hasFallDetected: false,
            location: nil
        )
        
        WKInterfaceDevice.current().play(.notification)
        NotificationCenter.default.post(
            name: Notification.Name("emergencyAlertTriggered"),
            object: nil,
            userInfo: ["healthData": healthData]
        )
    }
    
    private func notifyAbnormalHeartRate(_ value: Double) {
        NotificationCenter.default.post(
            name: Notification.Name("abnormalHeartRateDetected"),
            object: nil,
            userInfo: ["heartRate": value]
        )
    }
    
    private func notifyAbnormalBloodOxygen(_ value: Double) {
        NotificationCenter.default.post(
            name: Notification.Name("abnormalBloodOxygenDetected"),
            object: nil,
            userInfo: ["bloodOxygen": value]
        )
    }
}


// MARK: - Notification Names
extension Notification.Name {
    static let abnormalHeartRateDetected = Notification.Name("abnormalHeartRateDetected")
    static let abnormalBloodOxygenDetected = Notification.Name("abnormalBloodOxygenDetected")
    static let fallDetected = Notification.Name("fallDetected")
    static let emergencyAlertTriggered = Notification.Name("emergencyAlertTriggered")
}
