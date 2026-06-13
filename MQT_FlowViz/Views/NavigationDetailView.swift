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
                let actionText = selectedStep < currentTrace.steps.count ? currentTrace.steps[selectedStep].action : "Action"

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
        }
        .onChange(of: currentTrace) { _, _ in
            selectedStep = 0
        }
    }
}

#Preview {
    ZStack {
        Color.grayBackground.ignoresSafeArea()
        NavigationDetailView(currentTrace: CompilationTrace.previewMock)
    }
}
