//
//  CompilationStep.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//

import Foundation
import SwiftUI

/// An enum containing all supported action types.
enum ActionType: Hashable, Codable {
  case initial
  case optimization
  case synthesis
  case mapping
  case layout
  case routing
  case finalOptimization
  case terminate
  case other(String)

  init(stringValue: String) {
    switch stringValue.lowercased() {
    case "initial": self = .initial
    case "optimization": self = .optimization
    case "synthesis": self = .synthesis
    case "mapping": self = .mapping
    case "layout": self = .layout
    case "routing": self = .routing
    case "final_optimization": self = .finalOptimization
    case "terminate": self = .terminate
    default: self = .other(stringValue)
    }
  }

  var actionColor: Color {
    switch self {
    case .optimization, .finalOptimization: return .greenPrimary
    case .synthesis: return .redPrimary
    case .mapping, .layout, .routing: return .yellowPrimary
    case .initial, .terminate: return .gray
    case .other: return .bluePrimary
    }
  }
}

struct CompilationStep: Codable, Hashable, Identifiable {
  var id: Int { stepIndex }

  let stepIndex: Int
  let actionName: String
  let actionType: String
  let actionDuration: Float
  let reward: Double
  let currentDepth: Int
  let numQubits: Int
  let gatesPerOperation: [String: Int]
  let totalGates: Int
  let figuresOfMerit: FigureOfMeritMetrics
  let synthesized: Bool
  let laidOut: Bool
  let routed: Bool
  let isTerminal: Bool
  let circuitQasm3: String
  let programCommunication: Double
  let rawCriticalDepth: Double
  let entanglementRatio: Double
  let parallelism: Double
  let liveness: Double

  var actionTypeEnum: ActionType {
    ActionType(stringValue: actionType)
  }
}
