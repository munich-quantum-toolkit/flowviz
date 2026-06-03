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

                        case .multiQubit(let control, let target, _):
                            let yControl = CGFloat(control) * rowHeight + (rowHeight / 2)
                            let yTarget = CGFloat(target) * rowHeight + (rowHeight / 2)

                            // Standard solid line and dot
                            var path = Path()
                            path.move(to: CGPoint(x: xCenter, y: yControl))
                            path.addLine(to: CGPoint(x: xCenter, y: yTarget))
                            context.stroke(path, with: .color(.bluePrimary), lineWidth: 2)

                            let dotRect = CGRect(x: xCenter - 3, y: yControl - 3, width: 6, height: 6)
                            context.fill(Path(ellipseIn: dotRect), with: .color(.bluePrimary))

                            if let symbol = context.resolveSymbol(id: op.id) {
                                context.draw(symbol, at: CGPoint(x: xCenter, y: yTarget))
                            }

                        case .barrier(let qubits):
                            guard let minQ = qubits.min(), let maxQ = qubits.max() else { continue }
                            let yMin = CGFloat(minQ) * rowHeight + (rowHeight / 2) - 14
                            let yMax = CGFloat(maxQ) * rowHeight + (rowHeight / 2) + 14
                            let rect = CGRect(x: xCenter - 8, y: yMin, width: 16, height: yMax - yMin)

                            var path = Path()
                            path.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
                            context.stroke(path, with: .color(.bluePrimary), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))

                        case .nQubit(let controls, let targets, let label):
                            let allQubits = controls + targets
                            guard let minQ = allQubits.min(), let maxQ = allQubits.max() else { continue }

                            let yMin = CGFloat(minQ) * rowHeight + (rowHeight / 2)
                            let yMax = CGFloat(maxQ) * rowHeight + (rowHeight / 2)

                            let isSwap = label.lowercased() == "swap" || label.lowercased() == "cswap"

                            // 1. Draw the vertical line (dashed for swaps, solid for others)
                            var path = Path()
                            path.move(to: CGPoint(x: xCenter, y: yMin))
                            path.addLine(to: CGPoint(x: xCenter, y: yMax))

                            if isSwap {
                                context.stroke(path, with: .color(.bluePrimary), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            } else {
                                context.stroke(path, with: .color(.bluePrimary), lineWidth: 2)
                            }

                            // 2. Draw the solid dots for every control qubit
                            for control in controls {
                                let yControl = CGFloat(control) * rowHeight + (rowHeight / 2)
                                let dotRect = CGRect(x: xCenter - 3, y: yControl - 3, width: 6, height: 6)
                                context.fill(Path(ellipseIn: dotRect), with: .color(.bluePrimary))
                            }

                            // 3. Draw the targets (xmarks for swaps, resolved symbols for standard gates)
                            if isSwap {
                                let cross = Text(Image(systemName: "xmark"))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.bluePrimary)

                                for target in targets {
                                    let yTarget = CGFloat(target) * rowHeight + (rowHeight / 2)
                                    context.draw(cross, at: CGPoint(x: xCenter, y: yTarget))
                                }
                            } else {
                                if let symbol = context.resolveSymbol(id: op.id) {
                                    for target in targets {
                                        let yTarget = CGFloat(target) * rowHeight + (rowHeight / 2)
                                        context.draw(symbol, at: CGPoint(x: xCenter, y: yTarget))
                                    }
                                }
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
                            BoxedTextView(text: label.uppercased())
                                .tag(op.id)

                        case .nQubit(_, _, let label):
                            let lowerLabel = label.lowercased()
                            if lowerLabel != "swap" && lowerLabel != "cswap" {
                                BoxedTextView(text: label.uppercased())
                                    .tag(op.id)
                            }

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
        // Start with a base minimum width for every column so empty spaces don't collapse
        var columnWidths: [CGFloat] = Array(repeating: minWidth, count: max(circuit.totalMoments, 1))

        // Find the widest visual element in each moment column
        for op in circuit.operations {
            let requiredWidth: CGFloat

            switch op.type {
            case .singleQubit(_, let label, let parameter):
                let textLength = if let param = parameter { label.count + param.count + 2 } else { label.count }
                // estimate of ~8 points per char + 24pt padding inside the box + 16pt margin
                requiredWidth = CGFloat(textLength * 8) + 40

            case .multiQubit(_, _, let label), .nQubit(_, _, let label):
                let lowerLabel = label.lowercased()
                if lowerLabel == "swap" || lowerLabel == "cswap" {
                    // Swaps only draw xmarks, so they only need the minimum width
                    requiredWidth = minWidth
                } else {
                    requiredWidth = CGFloat(label.count * 8) + 40
                }

            case .barrier:
                // Barriers are just slim rectangles
                requiredWidth = 24

            case .measurement:
                // Measurements are fixed-size square icons
                requiredWidth = 40
            }

            // Overwrite the column width if this specific gate needs more room than what is currently allocated
            if requiredWidth > columnWidths[op.momentIndex] {
                columnWidths[op.momentIndex] = requiredWidth
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
