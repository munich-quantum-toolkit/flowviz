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
    @State var currentCircuit: ParsedCircuit
    @State private var stepInput: String = ""
    @FocusState private var isFocused: Bool

    // UI Constants for Canvas Alignment
    let rowHeight: CGFloat = 40
    let minColumnWidth: CGFloat = 50

    init(trace: CompilationTrace, step: Int = 0) {
        self.trace = trace
        self.totalSteps = trace.steps.count
        self.currentStep = step
        self.currentCircuit = QASMParser.parse(qasm: trace.steps[step].circuitQasm3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Circuit Evolution")
                .font(.title2.bold())

            DashboardCardView {
                CanvasRenderView(
                    currentCircuit: currentCircuit,
                    rowHeight: rowHeight,
                    defaultColumnWidth: minColumnWidth
                )

                // MARK: - Current Action Selector
                HStack(alignment: .center, spacing: 8) {
                    Text(trace.steps[currentStep].action)
                        .font(.callout.weight(.semibold))

                    Spacer()

                    // --- PREVIOUS BUTTON ---
                    Button(action: {
                        if currentStep > 0 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentStep -= 1
                                currentCircuit = QASMParser.parse(qasm: trace.steps[currentStep].circuitQasm3)
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(currentStep > 0 ? .black : .gray.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentStep == 0)

                    // --- TEXT INPUT ---
                    HStack(spacing: 8) {
                        TextField("", text: $stepInput)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .focused($isFocused)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.callout.weight(.semibold))
                            .frame(minWidth: 34)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding([.top, .bottom], 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.tertiary, lineWidth: 1)
                            )
                            // Filter out any non-numeric characters as the user types
                            .onChange(of: stepInput) { _, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    stepInput = filtered
                                }
                            }
                            .onSubmit {
                                applyManualStepInput()
                                isFocused = false
                            }

                        Text("/ \(totalSteps)")
                            .font(.callout.weight(.semibold))
                    }
                    // Needed to keep the text field in sync if the currentStep is changed via the Chevron buttons
                    .onAppear {
                        stepInput = String(currentStep + 1)
                    }
                    .onChange(of: currentStep) { _, newValue in
                        stepInput = String(newValue + 1)
                    }

                    // --- NEXT BUTTON ---
                    Button(action: {
                        if currentStep < totalSteps - 1 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentStep += 1
                                currentCircuit = QASMParser.parse(qasm: trace.steps[currentStep].circuitQasm3)
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(currentStep < totalSteps - 1 ? .black : .gray.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentStep == totalSteps - 1)
                }
            }
        }
        .contentShape(Rectangle())
    }

    /// Helper method that validates and applies the provided step input from the user.
    private func applyManualStepInput() {
        // If the user typed nonsense or left it empty, revert to the current step
        guard let parsed = Int(stepInput) else {
            stepInput = String(currentStep + 1)
            return
        }

        // Clamp the input so it can't go below 1 or above totalSteps
        let bounded = max(1, min(parsed, totalSteps))

        withAnimation(.easeInOut(duration: 0.2)) {
            // -1 to adjust the entered number to the corresponding array index
            currentStep = bounded - 1
            currentCircuit = QASMParser.parse(qasm: trace.steps[currentStep].circuitQasm3)
        }

        // Update the text field to reflect the applied value
        stepInput = String(bounded)
    }
}

#Preview {
    CircuitEvolutionView(trace: CompilationTrace.previewMock)
        .padding()
}
