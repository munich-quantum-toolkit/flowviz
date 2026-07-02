//
//  TooltipMetricsView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 02.07.26.
//

import SwiftUI

struct TooltipMetricsView: View {
    let currentStep: CompilationStep

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(currentStep.actionName)
                .font(.footnote.weight(.medium))
            Label("\(currentStep.numQubits) Qubits", systemImage: "circle.dotted.and.circle")
            Label(String(format: "Duration %.2f", currentStep.actionDuration), systemImage: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
            Label(String(format: "Depth %.2f", currentStep.rawCriticalDepth), systemImage: "arrow.down.to.line.compact")
            Label(String(format: "Parallelism %.2f", currentStep.parallelism), systemImage: "bolt")
            Label(String(format: "Liveness %.2f", currentStep.liveness), systemImage: "waveform.path.ecg")
            Label(String(format: "Entanglement %.2f", currentStep.entanglementRatio), systemImage: "point.3.connected.trianglepath.dotted")
        }
        .foregroundStyle(.black)
        .font(.footnote.weight(.regular))
        .symbolRenderingMode(.monochrome)
        .labelStyle(TooltipIconLabelStyle())
        .padding(12)
        .presentationCompactAdaptation(.popover)
    }
}

struct TooltipIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .frame(width: 18, alignment: .center)
                .foregroundStyle(Color.bluePrimary)

            configuration.title
        }
    }
}


#Preview {
    TooltipMetricsView(currentStep: CompilationTrace.previewMock.steps.first!)
}
