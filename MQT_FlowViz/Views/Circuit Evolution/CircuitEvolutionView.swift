//
//  CircuitEvolutionView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 22.05.26.
//
import SwiftUI

struct CircuitEvolutionView: View {
    let trace: CompilationTrace
    let totalSteps: Int

    @State var currentStep = 0
    @State var currentCircuit: ParsedCircuit? = nil

    // UI Constants for Canvas Alignment
    let rowHeight: CGFloat = 40
    let minColumnWidth: CGFloat = 50

    init(trace: CompilationTrace, step: Int = 0) {
        self.trace = trace
        self.totalSteps = trace.steps.count
        self._currentStep = State(initialValue: step)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Circuit Evolution")
                .font(.title2.bold())

            DashboardCardView {
                VStack(spacing: 16) {
                    if let circuit = currentCircuit {
                        CanvasRenderView(
                            currentCircuit: circuit,
                            rowHeight: rowHeight,
                            defaultColumnWidth: minColumnWidth
                        )
                    } else {
                        ProgressView()
                            .frame(height: 200)
                    }

                    ActionStepperView(
                        actionName: trace.steps[currentStep].action,
                        totalSteps: totalSteps,
                        currentStep: $currentStep
                    )
                }
                // Update the circuit whenever the stepper changes the step index
                .onChange(of: currentStep) { _, newStep in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentCircuit = QASMParser.parse(qasm: trace.steps[newStep].circuitQasm3)
                    }
                }
                // Reset the circuit & step upon change of trace
                .onChange(of: trace) { oldTrace, newTrace in
                    currentStep = 0
                    if let firstStep = newTrace.steps.first {
                        currentCircuit = QASMParser.parse(qasm: firstStep.circuitQasm3)
                    }
                }
                // Parse circuit if view appears & circuit has not already been parsed.
                .onAppear {
                    if currentCircuit == nil, let firstStep = trace.steps.first {
                        currentCircuit = QASMParser.parse(qasm: firstStep.circuitQasm3)
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    CircuitEvolutionView(trace: CompilationTrace.previewMock)
        .padding()
}
