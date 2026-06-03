//
//  CanvasRenderView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 22.05.26.
//

import SwiftUI

struct CanvasRenderView: View {
    let currentCircuit: ParsedCircuit
    let rowHeight: CGFloat
    let defaultColumnWidth: CGFloat

    let edgeBuffer: CGFloat = 8

    var body: some View {
        let canvasHeight = CGFloat(currentCircuit.wires.count) * rowHeight
        let (momentCenters, columnWidths) = calculateMomentCenters(circuit: currentCircuit, minWidth: defaultColumnWidth)

        // Total width is simply the last center + half its width + edge buffer
        let totalCalculatedWidth = (momentCenters.last ?? 0) + ((columnWidths.last ?? 0) / 2) + edgeBuffer

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
                Canvas { context, size in
                    // Draw horizontal wires
                    for i in 0..<currentCircuit.wires.count {
                        let yPosition = CGFloat(i) * rowHeight + (rowHeight / 2)

                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: yPosition))
                        path.addLine(to: CGPoint(x: size.width, y: yPosition))

                        context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 2)
                    }

                    // Draw Operations
                    for op in currentCircuit.operations {
                        let xCenter = momentCenters[op.momentIndex]

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
                                var path = Path()
                                path.move(to: CGPoint(x: xCenter, y: yControl))
                                path.addLine(to: CGPoint(x: xCenter, y: yTarget))
                                context.stroke(path, with: .color(.bluePrimary), lineWidth: 2)

                                let dotRect = CGRect(x: xCenter - 3, y: yControl - 3, width: 6, height: 6)
                                context.fill(Path(ellipseIn: dotRect), with: .color(.bluePrimary))

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
                    max(totalCalculatedWidth, containerWidth)
                }
                .frame(height: canvasHeight)
            }
        }
    }

    /// Helper function that estimates the required width for the gates and updates the moment centers accordingly.
    func calculateMomentCenters(circuit: ParsedCircuit, minWidth: CGFloat) -> (centers: [CGFloat], widths: [CGFloat]) {
        // minWidth needed so empty columns or swap gates don't collapse to 0 width.
        var columnWidths: [CGFloat] = Array(repeating: minWidth, count: max(circuit.totalMoments, 1))

        // Find the widest gate in each moment
        for op in circuit.operations {
            let textLength: Int

            // Extract the text that will actually be drawn
            switch op.type {
            case .singleQubit(_, let label, let parameter):
                // + 2 accounts for the "()" wrapped around the parameter
                textLength = if let param = parameter { label.count + param.count + 2 } else { label.count }
            case .multiQubit(_, _, let label), .nQubit(_, let label):
                textLength = label.count
            default:
                textLength = 0
            }

            // Estimate required width: ~4 points per character + 16 points padding + 32 points spacing
            let estimatedRequiredWidth = CGFloat(textLength * 4) + 16 + 32

            if estimatedRequiredWidth > columnWidths[op.momentIndex] {
                columnWidths[op.momentIndex] = estimatedRequiredWidth
            }
        }

        // Calculate the exact X-center coordinate for each moment
        var centers: [CGFloat] = []
        var currentX: CGFloat = edgeBuffer

        for width in columnWidths {
            centers.append(currentX + (width / 2))
            currentX += width
        }

        return (centers, columnWidths)
    }
}

#Preview {
    ZStack {
        Color.white
        CanvasRenderView(
            currentCircuit: QASMParser.parse(qasm: CompilationTrace.previewMock.steps[8].circuitQasm3),
            rowHeight: 40,
            defaultColumnWidth: 40
        )
        .padding()
    }
}
