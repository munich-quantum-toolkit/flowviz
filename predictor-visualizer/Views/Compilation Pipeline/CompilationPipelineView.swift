//
//  CompilationPipelineView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 18.05.26.
//

import SwiftUI

struct CompilationPipelineView: View {
    let trace: CompilationTrace
    let timelines: [TimelineSequence]
    let collapsedCount = 6

    @State var expandedPipeline: Bool = false

    init(trace: CompilationTrace) {
        self.trace = trace
        self.timelines = trace.getActionEvolution()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Compilation Pipeline")
                .font(.title2.bold())

            DashboardCardView(title: "Applied Actions") {
                VStack(alignment: .center, spacing: 16) {
                    TimelineView(sequences: Array(timelines.prefix(expandedPipeline ? timelines.count : collapsedCount)))

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            expandedPipeline.toggle()
                        }
                    }) {
                        Text(expandedPipeline ? "Show less 􀄨" : "Show all (\(timelines.count - collapsedCount) more) 􀄩")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.bluePrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    CompilationPipelineView(trace: CompilationTrace.previewMock)
        .frame(height: 550)
}
