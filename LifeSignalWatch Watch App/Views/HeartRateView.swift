//
//  HeartRateView.swift
//  LifeSignal
//
//  Created by Yunxin Liu on 3/15/25.
//

import SwiftUICore

struct HeartRateView: View {
    let value: Double?
    let isAbnormal: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(isAbnormal ? .red : .pink)
                Text("Heart Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isAbnormal {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(value != nil ? "\(Int(value!))" : "--")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isAbnormal ? .red : .primary)
                
                Text("BPM")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, -4)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
        )
    }
}
