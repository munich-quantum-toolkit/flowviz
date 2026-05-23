//
//  CircuitEvolutionView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 22.05.26.
//

import SwiftUI

struct CircuitEvolutionView: View {
    let trace: CompilationTrace
    @State var step = 0
    private var currentCircuit: ParsedCircuit

    // UI Constants for Canvas Alignment
    let rowHeight: CGFloat = 40
    let columnWidth: CGFloat = 60

    init(trace: CompilationTrace, step: Int = 0) {
        self.trace = trace
        self.step = step
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
            }
        }
    }
}

#Preview {
    CircuitEvolutionView(trace: CompilationTrace.previewMock)
        .padding()
}
