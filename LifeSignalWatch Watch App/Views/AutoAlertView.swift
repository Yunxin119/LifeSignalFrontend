//
//  AutoAlertView.swift
//  LifeSignal
//
//  Created by Yunxin Liu on 3/8/25.
//
import SwiftUI
import UIKit

struct AutoAlertView: View {
    @Binding var isActive: Bool
    @Binding var countdown: Int
    var onTimerComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                
                Text("Anomaly Detected")
                    .font(.caption)
                    .bold()
                
                Spacer()
                
                Text("\(countdown) seconds")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            HStack {
                Text("Auto notification will send after this count down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Cancel") {
                    isActive = false
                }
                .font(.caption2)
                .foregroundColor(.blue)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange, lineWidth: 1)
                )
        )
    }
}
