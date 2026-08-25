//
//  MDPEvolutionView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 13.05.26.
//

import SwiftUI

struct MDPEvolutionView: View {
  let trace: CompilationTrace
  @Binding var selectedStep: Int
  @State private var timelines: [TimelineSequence] = []

  init(trace: CompilationTrace, selectedStep: Binding<Int>) {
    self.trace = trace
    self._selectedStep = selectedStep
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Markov-Decision-Process Evolution")
        .font(.title2.bold())

      DashboardCardView(title: "Circuit State") {
        if timelines.contains(where: { !$0.stepRanges.isEmpty }) {
          TimelineView(sequences: timelines, highlightedStep: $selectedStep, steps: trace.steps)
        } else {
          Text("No MDP state evolution available")
            .font(.callout.weight(.semibold))
            .foregroundStyle(.secondary)
        }
      }
    }
    .task(id: trace.id) {
      let (synthesizedRanges, laidOutRanges, routedRanges) = trace.getMDPStateEvolution()

      await MainActor.run {
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
          ),
        ]
      }
    }
  }
}

#Preview {
  MDPEvolutionView(trace: CompilationTrace.previewMock, selectedStep: .constant(0))
}
