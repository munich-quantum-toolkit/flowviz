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
        let totalActions = max(trace.steps.count - 1, 0)

        IconizedRowView(
          icon: "sum",
          title: "Total Actions",
          detailText: "\(totalActions)"
        )

        Divider()

        // 3. Total Duration
        // placeholder for now until tracer adjustments can be made
        let totalDuration: Float = trace.totalDuration

        IconizedRowView(
          icon: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted",
          title: "Total Duration",
          detailText: String(format: "%.2fs", totalDuration)
        )

        Divider()

        // 4. Avg. Step Duration
        let avgDuration: Float = totalActions > 0 ? (totalDuration / Float(totalActions)) : 0.0

        IconizedRowView(
          icon: "circle.slash",
          title: "Avg. Step Duration",
          detailText: String(format: "%.2fs", avgDuration)
        )

        Divider()

        // 5. Longest Step Duration
        let longestStep = trace.steps.max(by: { $0.actionDuration < $1.actionDuration })
        IconizedRowView(
          icon: "clock.badge", title: "Max. Step Duration",
          detailText: longestStep != nil
            ? String(format: "%.2fs", longestStep!.actionDuration) : "N/A")

        Divider()

        // 6. Most Expensive Action Name
        IconizedRowView(
          icon: "dollarsign", title: "Most Expensive Action",
          detailText: longestStep != nil ? longestStep!.actionName : "N/A")

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
