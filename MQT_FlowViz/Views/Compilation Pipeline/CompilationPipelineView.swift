//
//  CompilationPipelineView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 18.05.26.
//

import SwiftUI

struct CompilationPipelineView: View {
    let trace: CompilationTrace
    @Binding var selectedStep: Int
    @State private var timelines: [TimelineSequence] = []
    let collapsedCount = 6

    @State var expandedPipeline: Bool = false

    init(trace: CompilationTrace, selectedStep: Binding<Int>) {
        self.trace = trace
        self._selectedStep = selectedStep
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Compilation Pipeline")
                .font(.title2.bold())

            DashboardCardView(title: "Applied Actions") {
                VStack(alignment: .center, spacing: 16) {
                    TimelineView(sequences: Array(timelines.prefix(expandedPipeline ? timelines.count : collapsedCount)), highlightedStep: $selectedStep, steps: trace.steps)

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            expandedPipeline.toggle()
                        }
                    }) {
                        Text(expandedPipeline ? "Show less \(Image(systemName: "arrow.up"))" : "Show all (\(timelines.count - collapsedCount) more) \(Image(systemName: "arrow.down"))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.bluePrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task(id: trace.id) {
            let rawEvolutionData = trace.getActionEvolution()

            self.timelines = rawEvolutionData.map { data in

                return TimelineSequence(
                    title: data.title,
                    stepRanges: data.ranges,
                    backgroundColor: Color.blueBackground,
                    textColor: Color.bluePrimary,
                    dotmarkHelpText: String(describing: data.type).capitalized,
                    dotmarkColor: data.type.actionColor
                )
            }
        }
    }
}

#Preview {
    CompilationPipelineView(trace: CompilationTrace.previewMock, selectedStep: .constant(0))
        .frame(height: 550)
}
