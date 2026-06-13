//
//  DeltasView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 13.06.26.
//

import SwiftUI

struct DeltasView: View {
    let trace: CompilationTrace
    @State private var insertedSwaps: Int? = nil

    var body: some View {
        DashboardCardView(title: "Deltas") {
            if let initialStep = trace.steps.first, let finalStep = trace.steps.last {
                VStack(spacing: 0) {

                    // 1. Qubits
                    let initialQubits = initialStep.numQubits
                    let finalQubits = finalStep.numQubits

                    DeltaRowView(
                        icon: "circle.dotted.and.circle",
                        title: "Qubits",
                        initialValue: "\(initialQubits)",
                        finalValue: "\(finalQubits)",
                        boxColors: getQubitsColor(from: initialQubits, to: finalQubits)
                    )

                    Divider()

                    // 2. Gates
                    let initialGates = initialStep.totalGates
                    let finalGates = finalStep.totalGates

                    DeltaRowView(
                        icon: "cpu",
                        title: "Gates",
                        initialValue: "\(initialGates)",
                        finalValue: "\(finalGates)",
                        boxColors: getGatesColor(from: initialGates, to: finalGates)
                    )

                    Divider()

                    // 3. Depth
                    let initialDepth = initialStep.currentDepth
                    let finalDepth = finalStep.currentDepth

                    DeltaRowView(
                        icon: "arrow.down.to.line",
                        title: "Depth",
                        initialValue: "\(initialDepth)",
                        finalValue: "\(finalDepth)",
                        boxColors: getDepthColor(from: initialDepth, to: finalDepth)
                    )

                    Divider()

                    // 4. Swaps
                    DeltaRowView(
                        icon: "arrow.up.arrow.down",
                        title: "Swaps",
                        initialValue: nil,
                        finalValue: insertedSwaps != nil ? "+\(insertedSwaps!)" : "N/A",
                        boxColors: insertedSwaps == 0 ? (.greenPrimary, .greenBackground) : (.redPrimary, .redBackground)
                    )
                }
                .task(id: finalStep.circuitQasm3) {
                    let count = await Self.calculateSwapGates(for: finalStep.circuitQasm3)

                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.insertedSwaps = count
                    }
                }
            }
        }
    }

    func getQubitsColor(from initial: Int, to final: Int) -> (textColor: Color, backgroundColor: Color) {
        if final > initial {
            return (.yellowPrimary, .yellowBackground)
        }
        return (.greenPrimary, .greenBackground)
    }

    func getGatesColor(from initial: Int, to final: Int) -> (textColor: Color, backgroundColor: Color) {
        guard initial > 0 else { return (.bluePrimary, .blueBackground) }
        let ratio = Double(final) / Double(initial)

        if ratio >= 3.0 {
            return (.redPrimary, .redBackground)
        } else if ratio >= 2.0 {
            return (.yellowPrimary, .yellowBackground)
        }
        return (.greenPrimary, .greenBackground)
    }

    func getDepthColor(from initial: Int, to final: Int) -> (textColor: Color, backgroundColor: Color) {
        guard initial > 0 else { return (.bluePrimary, .blueBackground) }
        let ratio = Double(final) / Double(initial)

        if ratio >= 3.0 {
            return (.redPrimary, .redBackground)
        } else if ratio >= 2.0 {
            return (.yellowPrimary, .yellowBackground)
        }
        return (.greenPrimary, .greenBackground)
    }

    // nonisolated to allow for background processing
    nonisolated private static func calculateSwapGates(for qasm: String) async -> Int {
        let tokens = qasm.components(separatedBy: .whitespacesAndNewlines)

        // Simply count how many times "swap" or "cswap" appears as an exact token
        return tokens.count { token in
            let lower = token.lowercased()
            return lower == "swap" || lower == "cswap"
        }
    }
}

// MARK: - Reusable Delta Row
struct DeltaRowView: View {
    let icon: String
    let title: String
    let initialValue: String?
    let finalValue: String
    let boxColors: (textColor: Color, backgroundColor: Color)

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    // Fixed width to align icons vertically
                    .frame(width: 20)

                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.bluePrimary)

            Spacer()

            HStack(spacing: 12) {
                if let initial = initialValue {
                    BoxedTextView(text: initial)

                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.bluePrimary)
                }

                BoxedTextView(
                    text: finalValue,
                    backgroundColor: boxColors.backgroundColor,
                    textColor: boxColors.textColor
                )
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        DeltasView(trace: CompilationTrace.previewMock)
            .frame(width: 320)
            .padding()
    }
}
