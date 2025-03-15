import SwiftUI
import HealthKit

struct WatchDashboardView: View {
    @StateObject private var healthMonitor = WatchHealthMonitor.shared
    @State private var showingEmergencyAlert = false
    @State private var countdown = 30
    @State private var isCountingDown = false
    @State private var timer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("LifeSignal")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                
                HeartRateView(value: healthMonitor.currentHeartRate, isAbnormal: healthMonitor.isHeartRateAbnormal)
                
                BloodOxygenView(value: healthMonitor.currentBloodOxygen, isAbnormal: healthMonitor.isBloodOxygenAbnormal)
                
                Button(action: {
                    showingEmergencyAlert = true
                }) {
                    Label("SOS", systemImage: "sos")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                
                if healthMonitor.isHeartRateAbnormal || healthMonitor.isBloodOxygenAbnormal {
                    AutoAlertView(
                        isActive: $isCountingDown,
                        countdown: $countdown,
                        onTimerComplete: {
                            healthMonitor.triggerEmergencyAlert()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            healthMonitor.startMonitoring()
            startAnomalyMonitoring()
        }
        .onDisappear {
            stopAnomalyMonitoring()
        }
        .alert(isPresented: $showingEmergencyAlert) {
            Alert(
                title: Text("Contact your emergency contacts?"),
                message: Text("This will send notifications to your emergency contacts"),
                primaryButton: .destructive(Text("Send")) {
                    healthMonitor.triggerEmergencyAlert()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    // Anomaly detection
    private func startAnomalyMonitoring() {
        if healthMonitor.isHeartRateAbnormal || healthMonitor.isBloodOxygenAbnormal {
            startCountdown()
        } else {
            stopCountdown()
        }
        
        NotificationCenter.default.addObserver(
            forName: .abnormalHeartRateDetected,
            object: nil,
            queue: .main
        ) { _ in
            startCountdown()
        }
        
        NotificationCenter.default.addObserver(
            forName: .abnormalBloodOxygenDetected,
            object: nil,
            queue: .main
        ) { _ in
            startCountdown()
        }
    }
    
    // Stop anomaly detection
    private func stopAnomalyMonitoring() {
        NotificationCenter.default.removeObserver(self)
        stopCountdown()
    }
    
    // Start countdown
    private func startCountdown() {
        guard !isCountingDown else { return }
        
        countdown = 30
        isCountingDown = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                stopCountdown()
                healthMonitor.triggerEmergencyAlert()
            }
        }
    }
    
    // Stop count down
    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
        isCountingDown = false
        countdown = 30
    }
}


// 预览
struct WatchDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WatchDashboardView()
    }
}
