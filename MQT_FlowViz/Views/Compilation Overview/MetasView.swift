//
//  MetasView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 13.06.26.
//

import SwiftUI

struct MetasView: View {
    let trace: CompilationTrace

    var body: some View {
        DashboardCardView(title: "Metas") {
            VStack(spacing: 0) {
                // 1. Policy
                MetaRowView(
                    icon: "chart.xyaxis.line",
                    title: "Policy",
                    valueText: trace.mdpPolicy.capitalized
                )
                
                Divider()
                
                // 2. Total Actions
                let totalActions = trace.steps.count - 1

                MetaRowView(
                    icon: "sum",
                    title: "Total Actions",
                    valueText: "\(totalActions)"
                )
                
                Divider()
                
                // 3. Total Duration
                // placeholder for now until tracer adjustments can be made
                let totalDuration: Double = 15.4
                
                MetaRowView(
                    icon: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted",
                    title: "Total Duration",
                    valueText: String(format: "%.1fs", totalDuration)
                )
                
                Divider()
                
                // 4. Avg. Step Duration
                let avgDuration: Double = totalActions > 0 ? (totalDuration / Double(totalActions)) : 0.0
                
                MetaRowView(
                    icon: "circle.slash", 
                    title: "Avg. Step Duration",
                    valueText: String(format: "%.1fs", avgDuration)
                )
            }
        }
    }
}

// MARK: - Reusable Meta Row
struct MetaRowView: View {
    let icon: String
    let title: String
    let valueText: String

    var body: some View {
        HStack(spacing: 12) {
            
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .frame(width: 20) 
            
            Text(title)
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            Text(valueText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(Color.bluePrimary)
        .padding(.vertical, 12)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        MetasView(trace: CompilationTrace.previewMock)
            .frame(width: 320)
            .padding()
    }
}
