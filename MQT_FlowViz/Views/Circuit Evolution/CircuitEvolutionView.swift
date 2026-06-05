//
//  CircuitEvolutionView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 22.05.26.
//
import SwiftUI

struct CircuitEvolutionView: View {
    let trace: CompilationTrace
    let currentStep: Int
    @State var currentCircuit: ParsedCircuit? = nil

    var currentActionName: String {
        currentStep >= 0 && currentStep < trace.steps.count ? trace.steps[currentStep].action : "Unknown Action"
    }

    // UI Constants for Canvas Alignment
    let rowHeight: CGFloat = 40
    let minColumnWidth: CGFloat = 50

    init(trace: CompilationTrace, currentStep: Int) {
        self.trace = trace
        self.currentStep = currentStep
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Circuit Evolution")
                .font(.title2.bold())

            DashboardCardView(title: currentActionName) {
                VStack(alignment: .center, spacing: 16) {
                    if let circuit = currentCircuit {
                        CanvasRenderView(
                            currentCircuit: circuit,
                            rowHeight: rowHeight,
                            defaultColumnWidth: minColumnWidth
                        )
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.small)
                                .progressViewStyle(.circular)
                                .foregroundStyle(.gray)
                                .tint(.gray)
                            Text("Parsing circuit...")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                    }
                }
                .onChange(of: currentStep) { _, newStep in
                    if newStep >= 0 && newStep < trace.steps.count {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentCircuit = QASMParser.parse(qasm: trace.steps[newStep].circuitQasm3)
                        }
                    }
                }
                .onChange(of: trace) { _, newTrace in
                    if currentStep >= 0 && currentStep < newTrace.steps.count {
                        currentCircuit = QASMParser.parse(qasm: newTrace.steps[currentStep].circuitQasm3)
                    }
                }
                .onAppear {
                    if currentCircuit == nil && currentStep >= 0 && currentStep < trace.steps.count {
                        currentCircuit = QASMParser.parse(qasm: trace.steps[currentStep].circuitQasm3)
                    }
                }
            }
            .clipped()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    CircuitEvolutionView(trace: CompilationTrace.previewMock, currentStep: 0)
        .padding()
}
