import Foundation

struct HealthAnalysis: Codable {
    let timestamp: String
    let isAnomaly: Bool
    let riskScore: Double
    let recommendations: [String]
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case isAnomaly = "is_anomaly"
        case riskScore = "risk_score"
        case recommendations
    }
}

class HealthAnalysisService {
    static let shared = HealthAnalysisService()
    
    #if DEBUG
    private let baseURL = "http://localhost:5100/api"  // Development
    #else
    private let baseURL = "http://your-production-server:5100/api"  // Production
    #endif
    
    private init() {}
    
    func analyzeHealthData(_ healthData: HealthData) async throws -> HealthAnalysis {
        guard let url = URL(string: "\(baseURL)/analyze_health_data") else {
            throw URLError(.badURL)
        }
        
        let payload = [
            "heart_rate": healthData.heartRate,
            "blood_oxygen": healthData.bloodOxygen
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        // Allow local connections in development
        #if DEBUG
        if #available(iOS 15.0, *) {
            let config = URLSessionConfiguration.default
            config.waitsForConnectivity = true
            let session = URLSession(configuration: config)
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode(HealthAnalysis.self, from: data)
        }
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(HealthAnalysis.self, from: data)
    }
} 