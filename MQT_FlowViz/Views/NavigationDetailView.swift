//
//  NavigationDetailView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//

import SwiftUI

struct NavigationDetailView: View {
  let currentTrace: CompilationTrace
  @State var selectedStep: Int = 0
  @State private var exportURL: URL?

  var body: some View {
    ScrollView(.vertical, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 24) {
        CompilationOverviewView(trace: currentTrace)
        CompilationInformationView(trace: currentTrace)
        CircuitEvolutionView(trace: currentTrace, currentStep: selectedStep)
        CompilationPipelineView(trace: currentTrace, selectedStep: $selectedStep)
        MDPEvolutionView(trace: currentTrace, selectedStep: $selectedStep)
        FooterNoteView()
      }
      .padding(EdgeInsets(top: 0, leading: 24, bottom: 24, trailing: 24))
    }
    .scrollDismissesKeyboard(.interactively)
    .hideKeyboardOnTap()
    .toolbar {
      ToolbarItem(placement: .principal) {
        let actionText =
          selectedStep < currentTrace.steps.count
          ? currentTrace.steps[selectedStep].actionName : "Action"

        Text(actionText)
          #if os(macOS)
            .font(.callout.weight(.semibold))
          #else
            .font(.headline)
          #endif
          .foregroundStyle(.black)
          .padding([.leading, .trailing], 12)
          .animation(nil, value: actionText)
      }

      ToolbarItem(placement: .primaryAction) {
        ActionStepperView(
          totalSteps: currentTrace.steps.count,
          currentStep: $selectedStep
        )
        .padding([.leading, .trailing], 12)
      }

      ToolbarSpacer(.fixed)

      ToolbarItem(placement: .primaryAction) {
        // ShareLink accepts the URL of a file to be shared
        if let url = exportURL {
          ShareLink(item: url) {
            Image(systemName: "square.and.arrow.up")
              .fontWeight(.medium)
          }
          .help("Export Trace as JSON")
          .buttonStyle(.bordered)
          .foregroundStyle(.black)
        } else {
          // Fallback while generating or if generation fails
          Image(systemName: "square.and.arrow.up")
            .fontWeight(.medium)
            .foregroundColor(.black)
        }
      }
    }
    .onAppear {
      exportURL = try? DataHandler.generateExportURL(for: currentTrace)
    }
    .onChange(of: currentTrace) { _, newTrace in
      selectedStep = 0
      exportURL = try? DataHandler.generateExportURL(for: newTrace)
    }
  }
}

#Preview {
  ZStack {
    Color.grayBackground.ignoresSafeArea()
    NavigationDetailView(currentTrace: CompilationTrace.previewMock)
  }
}
