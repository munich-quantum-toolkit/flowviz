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
                let liveness = finalStep?.liveness
                ResultRowView(
                    icon: "waveform.path.ecg",
                    title: "Liveness",
                    valueText: liveness != nil ? String(format: "%.2f", liveness!) : "N/A",
                    gaugeValue: liveness,
                )

                Divider()

                // 5. Parallelism
                let parallelism = finalStep?.parallelism
                ResultRowView(
                    icon: "bolt",
                    title: "Parallelism",
                    valueText: parallelism != nil ? String(format: "%.2f", parallelism!) : "N/A",
                    gaugeValue: parallelism,
                )
            }
        }
    }
}

struct ResultRowView: View {
    let icon: String
    let title: String
    let valueText: String

    // Optional Gauge parameters
    var gaugeValue: Double? = nil
    var gaugeColors: (stroke: Color, background: Color) = (.bluePrimary, .blueBackground)

    @State private var animatedValue: Double = 0

    var body: some View {
        IconizedRowView(icon: icon, title: title) {
            // Inject the tiny animated gauge if a value was provided
            if let targetValue = gaugeValue {
                ZStack {
                    Circle()
                        .stroke(gaugeColors.background, lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: CGFloat(animatedValue))
                        .stroke(gaugeColors.stroke, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 16, height: 16)
                .onAppear {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.1)) {
                        animatedValue = targetValue
                    }
                }
            }

            Text(valueText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
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
