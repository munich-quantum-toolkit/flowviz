//
//  ResultsView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 13.06.26.
//

import SwiftUI

struct ResultsView: View {
    let trace: CompilationTrace

    var body: some View {
        let finalStep = trace.steps.last

        DashboardCardView(title: "Results") {
            VStack(spacing: 0) {

                // 1. Device Context
                ResultRowView(
                    icon: "target",
                    title: "Device",
                    valueText: trace.device.formattedDeviceName
                )

                Divider()

                // 2. Estimated Success Probability
                let esp = finalStep?.figuresOfMerit.successProbability?.value
                ResultRowView(
                    icon: "checkmark.seal",
                    title: "Estimated Success",
                    valueText: esp != nil ? String(format: "%.2f%", esp!) : "N/A",
                    gaugeValue: esp,
                )

                Divider()

                // 3. Expected Fidelity
                let fidelity = finalStep?.figuresOfMerit.expectedFidelity.value
                ResultRowView(
                    icon: "gauge.with.dots.needle.bottom.100percent",
                    title: "Expected Fidelity",
                    valueText: fidelity != nil ? String(format: "%.2f%", fidelity!) : "N/A",
                    gaugeValue: fidelity,
                )

                Divider()

                // 4. Liveness
                let liveness = finalStep?.liveness ?? 0
                ResultRowView(
                    icon: "waveform.path.ecg",
                    title: "Liveness",
                    valueText: String(format: "%.2f", liveness),
                    gaugeValue: liveness,
                )

                Divider()

                // 5. Parallelism
                let parallelism = finalStep?.parallelism ?? 0
                ResultRowView(
                    icon: "bolt",
                    title: "Parallelism",
                    valueText: String(format: "%.2f", parallelism),
                    gaugeValue: parallelism,
                )
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        ResultsView(trace: CompilationTrace.previewMock)
            .frame(width: 320)
            .padding()
    }
}
