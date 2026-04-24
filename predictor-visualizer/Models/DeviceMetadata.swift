//
//  DeviceMetadata.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//


import Foundation

struct DeviceMetadata: Codable, Hashable {
    let description: String
    let deviceQubits: Int
    let nativeGates: [String]
    let topology: [TopologyEdge]
    let calibrationData: [String: [GateCalibration]]
}
