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

    var formattedDeviceName: String {
        let components = description.components(separatedBy: "_")

        guard let vendor = components.first else { return description }

        let capitalizedRest = components.dropFirst().map { $0.capitalized }
        let finalComponents = [vendor.uppercased()] + capitalizedRest

        return finalComponents.joined(separator: " ")
    }
}
