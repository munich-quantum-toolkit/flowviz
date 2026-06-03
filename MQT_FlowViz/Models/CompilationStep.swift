//
//  CompilationStep.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//


import Foundation

struct CompilationStep: Codable, Hashable, Identifiable {
    var id: Int { stepIndex } // SwiftUI requires an 'id' for lists, stepIndex is perfect!
    
    let stepIndex: Int
    let action: String
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
}
