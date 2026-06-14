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
                IconizedRowView(
                    icon: "chart.xyaxis.line",
                    title: "Policy",
                    detailText: trace.mdpPolicy.capitalized
                )
                
                Divider()
                
                // 2. Total Actions
                let totalActions = trace.steps.count - 1

                IconizedRowView(
                    icon: "sum",
                    title: "Total Actions",
                    detailText: "\(totalActions)"
                )
                
                Divider()
                
                // 3. Total Duration
                // placeholder for now until tracer adjustments can be made
                let totalDuration: Double = 15.4
                
                IconizedRowView(
                    icon: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted",
                    title: "Total Duration",
                    detailText: String(format: "%.1fs", totalDuration)
                )
                
                Divider()
                
                // 4. Avg. Step Duration
                let avgDuration: Double = totalActions > 0 ? (totalDuration / Double(totalActions)) : 0.0
                
                IconizedRowView(
                    icon: "circle.slash", 
                    title: "Avg. Step Duration",
                    detailText: String(format: "%.1fs", avgDuration)
                )
            }
        }
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
