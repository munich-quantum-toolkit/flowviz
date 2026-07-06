//
//  TooltipMetricsView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 02.07.26.
//

import SwiftUI

struct TooltipMetricsView: View {
    let currentStep: CompilationStep
    #if os(macOS)
    let tooltipFont: Font = .subheadline
    #else
    let tooltipFont: Font = .footnote
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(currentStep.actionName)
                .font(tooltipFont.weight(.medium))
            Label("Qubits: \(currentStep.numQubits)", systemImage: "circle.dotted.and.circle")
            Label(String(format: "Duration: %.2fs", currentStep.actionDuration), systemImage: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
            Label(String(format: "Depth: %.2f", currentStep.rawCriticalDepth), systemImage: "arrow.down.to.line.compact")
            Label(String(format: "Parallelism: %.2f", currentStep.parallelism), systemImage: "bolt")
            Label(String(format: "Liveness: %.2f", currentStep.liveness), systemImage: "waveform.path.ecg")
            Label(String(format: "Entanglement: %.2f", currentStep.entanglementRatio), systemImage: "camera.filters")
        }
        .foregroundStyle(.black)
        .font(tooltipFont.weight(.regular))
        .symbolRenderingMode(.monochrome)
        .labelStyle(TooltipIconLabelStyle())
        // macOS tooltips have a smaller corner radius, hence we need less padding
        #if os(macOS)
        .padding(16)
        #else
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
        #endif
        .presentationCompactAdaptation(.popover)
    }
}

struct TooltipIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .frame(width: 16, alignment: .center)
                .foregroundStyle(Color.bluePrimary)

            configuration.title
        }
    }
}


#Preview {
    TooltipMetricsView(currentStep: CompilationTrace.previewMock.steps.first!)
}
