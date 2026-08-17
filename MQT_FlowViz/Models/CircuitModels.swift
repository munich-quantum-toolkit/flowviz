//
//  CircuitModels.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 22.05.26.
//

import Foundation

/// Represents a wire of the circuit.
struct Wire: Identifiable, Hashable {
  let id: Int  // e.g., 4
  let label: String  // e.g., "q[4]"
  let isClassical: Bool  // quantum wire or classical wire
}

/// Defines exactly what the Canvas needs to draw.
enum GateVisualType {
  case singleQubit(target: Int, label: String, parameter: String?)
  case multiQubit(control: Int, target: Int, label: String, parameter: String?)
  case nQubit(controls: [Int], targets: [Int], label: String)  // For gates involving 3+ qubits
  case barrier(qubits: [Int])
  case measurement(qubit: Int, classicalBit: Int?)
}

/// Represents a circuit operation and contains information about its position on the wire.
struct CircuitOperation: Identifiable {
  let id = UUID()
  let type: GateVisualType

  // The exact X-coordinate column where this gate should be drawn
  var momentIndex: Int = 0

  // Holds the visual index of the classical wire controlling this gate (if inside an 'if' block)
  var classicalControls: [Int] = []

  // Used by the Canvas to calculate vertical lines (e.g. for CNOTs or Barriers)
  var involvedQubits: [Int] {
    switch type {
    case .singleQubit(let t, _, _): return [t]
    case .multiQubit(let c, let t, _, _): return [c, t]
    case .nQubit(let controls, let targets, _): return controls + targets
    case .barrier(let qs): return qs
    case .measurement(let q, _): return [q]
    }
  }
}

/// The final parsed circuit that can be drawn by the UI.
struct ParsedCircuit {
  let wires: [Wire]
  let operations: [CircuitOperation]

  // Used to calculate the total width of the ScrollView
  var totalMoments: Int {
    (operations.map { $0.momentIndex }.max() ?? 0) + 1
  }
}
