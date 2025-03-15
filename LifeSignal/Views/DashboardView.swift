import SwiftUI
import HealthKit

struct DashboardView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var showingAuthorizationAlert = false
    @State private var authorizationError: Error?
    @State private var showingTestButtons = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Health Metrics Cards
                    HealthMetricsView(healthData: healthKitManager.latestHealthData)
                    
                    // Status Indicators
                    VStack(spacing: 10) {
                        StatusIndicatorView(
                            isMonitoring: healthKitManager.isAuthorized,
                            title: "Health Monitoring",
                            activeText: "Active",
                            inactiveText: "Inactive"
                        )
                        
                        StatusIndicatorView(
                            isMonitoring: notificationManager.notificationsEnabled,
                            title: "Notifications",
                            activeText: "Enabled",
                            inactiveText: "Disabled",
                            iconName: notificationManager.notificationsEnabled ? "bell.fill" : "bell.slash.fill"
                        )
                    }
                    
                    // Test Buttons (for development only)
                    if showingTestButtons {
                        VStack(spacing: 15) {
                            Text("Test Notifications")
                                .font(.headline)
                            
                            Button("Test Heart Rate Alert") {
                                notificationManager.sendHeartRateAlert(heartRate: 130)
                            }
                            .buttonStyle(AlertButtonStyle(color: .red))
                            
                            Button("Test Blood Oxygen Alert") {
                                notificationManager.sendBloodOxygenAlert(bloodOxygen: 92)
                            }
                            .buttonStyle(AlertButtonStyle(color: .blue))
                            
                            Button("Test Fall Detection") {
                                notificationManager.sendFallDetectedAlert()
                            }
                            .buttonStyle(AlertButtonStyle(color: .orange))
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                    
                    // Emergency Contacts Section
                    EmergencyContactsPreview()
                }
                .padding()
            }
            .navigationTitle("Health Monitor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingTestButtons.toggle()
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .alert("Authorization Error",
               isPresented: $showingAuthorizationAlert,
               presenting: authorizationError) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .task {
            await requestHealthKitAuthorization()
            notificationManager.requestAuthorization()
        }
    }
    
    private func requestHealthKitAuthorization() async {
        do {
            try await healthKitManager.requestAuthorization()
            healthKitManager.startMonitoring()
        } catch {
            authorizationError = error
            showingAuthorizationAlert = true
        }
    }
}

struct HealthMetricsView: View {
    let healthData: HealthData?
    
    var body: some View {
        VStack(spacing: 15) {
            // Heart Rate Card
            MetricCard(
                title: "Heart Rate",
                value: healthData?.heartRate.map { "\(Int($0))" } ?? "--",
                unit: "BPM",
                icon: "heart.fill",
                color: .red
            )
            
            // Blood Oxygen Card
            MetricCard(
                title: "Blood Oxygen",
                value: healthData?.bloodOxygen.map { String(format: "%.1f", $0) } ?? "--",
                unit: "%",
                icon: "lungs.fill",
                color: .blue
            )
            
            // Fall Detection Status
            if healthData?.hasFallDetected == true {
                FallDetectionAlert()
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                Text(unit)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct StatusIndicatorView: View {
    let isMonitoring: Bool
    let title: String
    let activeText: String
    let inactiveText: String
    var iconName: String? = nil
    
    init(isMonitoring: Bool, title: String, activeText: String, inactiveText: String, iconName: String? = nil) {
        self.isMonitoring = isMonitoring
        self.title = title
        self.activeText = activeText
        self.inactiveText = inactiveText
        self.iconName = iconName ?? (isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            HStack {
                Image(systemName: iconName ?? "")
                    .foregroundColor(isMonitoring ? .green : .red)
                Text(isMonitoring ? activeText : inactiveText)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct AlertButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.7 : 0.3))
            .foregroundColor(color)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct EmergencyContactsPreview: View {
    // This would normally use real contacts from EmergencyContactManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Emergency Contacts")
                .font(.headline)
            
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.blue)
                Text("+ Add Contact")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 3)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct FallDetectionAlert: View {
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("Fall Detected!")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button("Clear") {
                // TODO: Implement clear action
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(NotificationManager.shared)
    }
} 