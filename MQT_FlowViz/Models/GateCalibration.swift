//
//  GateCalibration.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//


import Foundation

struct GateCalibration: Codable, Hashable {
    let qubits: [Int]
    let duration: Double?
    let error: Double?
}
