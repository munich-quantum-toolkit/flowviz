//
//  CompilationOverviewView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 04.05.26.
//
import SwiftUI

struct CompilationOverviewView: View {
  let trace: CompilationTrace

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Compilation Overview")
        .font(.title2.bold())

      HStack(spacing: 16) {
        ResultsView(trace: trace)
        DeltasView(trace: trace)
        MetasView(trace: trace)
      }
    }
  }
}

#Preview {
  ZStack {
    Color.grayBackground.ignoresSafeArea()
    CompilationOverviewView(trace: .previewMock)
      .padding()
  }
}
