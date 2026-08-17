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
  @State private var initialMultiQubits: Int? = nil
  @State private var finalMultiQubits: Int? = nil

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

          // 2. Total Gates
          let initialGates = initialStep.totalGates
          let finalGates = finalStep.totalGates

          DeltaRowView(
            icon: "cpu",
            title: "Total Gates",
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

          // 4. Multi-Qubit Gates
          DeltaRowView(
            icon: "point.3.connected.trianglepath.dotted",
            title: "Multi-Qubit",
            initialValue: initialMultiQubits != nil ? "\(initialMultiQubits!)" : nil,
            finalValue: finalMultiQubits != nil ? "\(finalMultiQubits!)" : "N/A",
            boxColors: (initialMultiQubits != nil && finalMultiQubits != nil)
              ? getMultiQubitGatesColor(from: initialMultiQubits!, to: finalMultiQubits!)
              : (.bluePrimary, .blueBackground)
          )

          Divider()

          // 5. Swaps
          DeltaRowView(
            icon: "arrow.up.arrow.down",
            title: "Swaps",
            initialValue: nil,
            finalValue: insertedSwaps != nil ? "+\(insertedSwaps!)" : "N/A",
            boxColors: insertedSwaps == 0
              ? (.greenPrimary, .greenBackground) : (.redPrimary, .redBackground)
          )
        }
        .task(id: trace.id) {
          let finalQasm = finalStep.circuitQasm3
          let initialQasm = initialStep.circuitQasm3

          let (swaps, initialMulti, finalMulti) = await Task.detached {
            let s = await calculateSwapGates(for: finalQasm)
            let i = await calculateMultiQubitGates(for: initialQasm)
            let f = await calculateMultiQubitGates(for: finalQasm)

            return (s, i, f)
          }.value

          withAnimation(.easeInOut(duration: 0.2)) {
            self.insertedSwaps = swaps
            self.initialMultiQubits = initialMulti
            self.finalMultiQubits = finalMulti
          }
        }
      }
    }
  }

  func getQubitsColor(from initial: Int, to final: Int) -> (
    textColor: Color, backgroundColor: Color
  ) {
    if final > initial {
      return (.yellowPrimary, .yellowBackground)
    }
    return (.greenPrimary, .greenBackground)
  }

  func getGatesColor(from initial: Int, to final: Int) -> (textColor: Color, backgroundColor: Color)
  {
    guard initial > 0 else { return (.bluePrimary, .blueBackground) }
    let ratio = Double(final) / Double(initial)

    if ratio >= 3.0 {
      return (.redPrimary, .redBackground)
    } else if ratio >= 2.0 {
      return (.yellowPrimary, .yellowBackground)
    }
    return (.greenPrimary, .greenBackground)
  }

  func getDepthColor(from initial: Int, to final: Int) -> (textColor: Color, backgroundColor: Color)
  {
    guard initial > 0 else { return (.bluePrimary, .blueBackground) }
    let ratio = Double(final) / Double(initial)

    if ratio >= 3.0 {
      return (.redPrimary, .redBackground)
    } else if ratio >= 2.0 {
      return (.yellowPrimary, .yellowBackground)
    }
    return (.greenPrimary, .greenBackground)
  }

  func getMultiQubitGatesColor(from initial: Int, to final: Int) -> (
    textColor: Color, backgroundColor: Color
  ) {
    guard initial > 0 else { return (.bluePrimary, .blueBackground) }
    let ratio = Double(final) / Double(initial)

    if ratio >= 2.0 {
      return (.redPrimary, .redBackground)
    } else if ratio > 1.0 {
      return (.yellowPrimary, .yellowBackground)
    }
    return (.greenPrimary, .greenBackground)
  }

  func calculateSwapGates(for qasm: String) async -> Int {
    let tokens = qasm.components(separatedBy: .whitespacesAndNewlines)

    // Simply count how many times "swap" or "cswap" appears as an exact token
    return tokens.count { token in
      let lower = token.lowercased()
      return lower == "swap" || lower == "cswap"
    }
  }

  func calculateMultiQubitGates(for qasm: String) async -> Int? {
    guard let circuit = try? QASMParser.parse(qasm: qasm) else { return nil }

    return circuit.operations.reduce(0) { count, op in
      switch op.type {
      case .multiQubit, .nQubit:
        return count + 1
      default:
        return count
      }
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
    IconizedRowView(icon: icon, title: title) {
      HStack(spacing: 12) {
        if let initial = initialValue {
          Text(initial)
            .font(.caption.bold())
            .foregroundStyle(.bluePrimary)
            .padding(6)
            .frame(minWidth: 40)
            .background(.blueBackground)
            .cornerRadius(8)

          Image(systemName: "arrow.right")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.bluePrimary)
        }

        Text(finalValue)
          .font(.caption.bold())
          .foregroundStyle(boxColors.textColor)
          .padding(6)
          .frame(minWidth: 40)
          .background(boxColors.backgroundColor)
          .cornerRadius(8)
      }
    }
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
