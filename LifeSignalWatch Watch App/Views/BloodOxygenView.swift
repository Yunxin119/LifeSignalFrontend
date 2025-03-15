//
//  BloodOxygenView.swift
//  LifeSignal
//
//  Created by Yunxin Liu on 3/15/25.
//

import SwiftUICore
import UIKit

struct BloodOxygenView: View {
    let value: Double?
    let isAbnormal: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "lungs.fill")
                    .foregroundColor(isAbnormal ? .red : .blue)
                Text("Blood Oxygen")
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
                Text(value != nil ? String(format: "%.1f", value!) : "--")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isAbnormal ? .red : .primary)
                
                Text("%")
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
