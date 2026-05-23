//
//  CircuitEvolutionView.swift
//  predictor-visualizer
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
    let columnWidth: CGFloat = 60

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
                HStack(alignment: .top, spacing: 16) {
                    // --- LEFT COLUMN: Fixed Qubit Labels ---
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(currentCircuit.wires) { wire in
                            Text(wire.label)
                                .font(.system(.subheadline, design: .monospaced).bold())
                                .foregroundColor(Color.bluePrimary)
                                .frame(height: rowHeight)
                        }
                    }

                    // --- RIGHT COLUMN: Scrollable Canvas ---
                    ScrollView(.horizontal, showsIndicators: true) {
                        let calculatedWidth = CGFloat(max(currentCircuit.totalMoments, 1)) * columnWidth
                        let canvasHeight = CGFloat(currentCircuit.wires.count) * rowHeight

                        Canvas { context, size in
                            // 1. Draw horizontal wires
                            for i in 0..<currentCircuit.wires.count {
                                let yPosition = CGFloat(i) * rowHeight + (rowHeight / 2)

                                var path = Path()
                                path.move(to: CGPoint(x: 0, y: yPosition))
                                path.addLine(to: CGPoint(x: size.width, y: yPosition))

                                context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 2)
                            }

                            // 2. Draw Operations
                            for op in currentCircuit.operations {
                                // X-coordinate is identical for all gates applied at this moment
                                let xCenter = CGFloat(op.momentIndex) * columnWidth + (columnWidth / 2)

                                switch op.type {
                                case .singleQubit(let target, _, _), .measurement(let target, _):
                                    let yCenter = CGFloat(target) * rowHeight + (rowHeight / 2)

                                    if let symbol = context.resolveSymbol(id: op.id) {
                                        context.draw(symbol, at: CGPoint(x: xCenter, y: yCenter))
                                    }

                                case .multiQubit(let control, let target, let label):
                                    let yControl = CGFloat(control) * rowHeight + (rowHeight / 2)
                                    let yTarget = CGFloat(target) * rowHeight + (rowHeight / 2)

                                    if label.lowercased() == "swap" {
                                        // SWAP GATE: Dashed vertical line
                                        var path = Path()
                                        path.move(to: CGPoint(x: xCenter, y: yControl))
                                        path.addLine(to: CGPoint(x: xCenter, y: yTarget))
                                        context.stroke(path, with: .color(.bluePrimary), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                                        let cross = Text(Image(systemName: "xmark"))
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.bluePrimary)

                                        context.draw(cross, at: CGPoint(x: xCenter, y: yControl))
                                        context.draw(cross, at: CGPoint(x: xCenter, y: yTarget))
                                    } else {
                                        // STANDARD CNOT/CONTROL GATE: Solid line with control dot
                                        var path = Path()
                                        path.move(to: CGPoint(x: xCenter, y: yControl))
                                        path.addLine(to: CGPoint(x: xCenter, y: yTarget))
                                        context.stroke(path, with: .color(.bluePrimary), lineWidth: 2)

                                        // control dot
                                        let dotRect = CGRect(x: xCenter - 3, y: yControl - 3, width: 6, height: 6)
                                        context.fill(Path(ellipseIn: dotRect), with: .color(.bluePrimary))

                                        // BoxedTextView at the target
                                        if let symbol = context.resolveSymbol(id: op.id) {
                                            context.draw(symbol, at: CGPoint(x: xCenter, y: yTarget))
                                        }
                                    }

                                case .barrier(let qubits):
                                    guard let minQ = qubits.min(), let maxQ = qubits.max() else { continue }
                                    let yMin = CGFloat(minQ) * rowHeight + (rowHeight / 2) - 14
                                    let yMax = CGFloat(maxQ) * rowHeight + (rowHeight / 2) + 14
                                    let rect = CGRect(x: xCenter - 8, y: yMin, width: 16, height: yMax - yMin)

                                    var path = Path()
                                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
                                    context.stroke(path, with: .color(.bluePrimary), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))

                                case .nQubit(let qubits, _):
                                    guard let minQ = qubits.min(), let maxQ = qubits.max() else { continue }
                                    let yMin = CGFloat(minQ) * rowHeight + (rowHeight / 2)
                                    let yMax = CGFloat(maxQ) * rowHeight + (rowHeight / 2)

                                    var path = Path()
                                    path.move(to: CGPoint(x: xCenter, y: yMin))
                                    path.addLine(to: CGPoint(x: xCenter, y: yMax))
                                    context.stroke(path, with: .color(.bluePrimary), lineWidth: 2)

                                    if let symbol = context.resolveSymbol(id: op.id) {
                                        context.draw(symbol, at: CGPoint(x: xCenter, y: (yMin + yMax) / 2))
                                    }
                                }
                            }

                        } symbols: {
                            // 3. Definition of SwiftUI Views the Canvas will render
                            ForEach(currentCircuit.operations) { op in
                                switch op.type {
                                case .singleQubit(_, let label, let param):
                                    let text = param != nil ? "\(label.uppercased())(\(param!))" : label.uppercased()
                                    BoxedTextView(text: text)
                                        .tag(op.id)

                                case .multiQubit(_, _, let label):
                                    if label.lowercased() != "swap" {
                                        BoxedTextView(text: label.uppercased())
                                            .tag(op.id)
                                    }

                                case .nQubit(_, let label):
                                    BoxedTextView(text: label.uppercased())
                                        .tag(op.id)

                                case .measurement:
                                    Image(systemName: "scope")
                                        .font(.caption.bold())
                                        .foregroundColor(.bluePrimary)
                                        .padding(8)
                                        .background(.blueBackground)
                                        .cornerRadius(8)
                                        .tag(op.id)

                                case .barrier:
                                    EmptyView().tag(op.id)
                                }
                            }
                        }
                        .containerRelativeFrame(.horizontal) { containerWidth, _ in
                            max(calculatedWidth, containerWidth)
                        }
                        .frame(height: canvasHeight)
                    }
                }

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
                            .foregroundColor(currentStep > 0 ? .primary : .gray.opacity(0.3))
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
                            .foregroundColor(currentStep < totalSteps - 1 ? .primary : .gray.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentStep == totalSteps - 1)
                }
            }
        }
        .onTapGesture {
            isFocused = false
        }
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
