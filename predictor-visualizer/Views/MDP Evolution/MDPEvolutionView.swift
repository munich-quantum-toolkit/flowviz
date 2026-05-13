//
//  MDPEvolutionView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 13.05.26.
//

import SwiftUI

struct MDPEvolutionView: View {
    let trace: CompilationTrace
    let timelines: [TimelineSequence]

    init(trace: CompilationTrace) {
        self.trace = trace

        let (synthesizedRanges, laidOutRanges, routedRanges) = trace.getMDPStateEvolution()

        self.timelines = [
            TimelineSequence(
                title: "Synthesized",
                stepRanges: synthesizedRanges,
                backgroundColor: Color.redBackground,
                textColor: Color.redPrimary
            ),
            TimelineSequence(
                title: "Laid Out",
                stepRanges: laidOutRanges,
                backgroundColor: Color.yellowBackground,
                textColor: Color.yellowPrimary
            ),
            TimelineSequence(
                title: "Routed",
                stepRanges: routedRanges,
                backgroundColor: Color.greenBackground,
                textColor: Color.greenPrimary
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Markov-Decision-Process Evolution")
                .font(.title2.bold())

            DashboardCardView(title: "Circuit State") {
                TimelineView(sequences: timelines)
            }
        }
    }
}

#Preview {
    MDPEvolutionView(trace: CompilationTrace.previewMock)
}
