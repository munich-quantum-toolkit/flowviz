//
//  DeviceMetadata.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//

import Foundation

struct DeviceMetadata: nonisolated Codable, Hashable, Sendable {
  let name: String
  let deviceQubits: Int
  let nativeGates: [String]
  let topology: [TopologyEdge]
  let calibrationData: [String: [GateCalibration]]

  var formattedDeviceName: String {
    let components = name.components(separatedBy: "_")

    guard let vendor = components.first else { return name }

    let capitalizedRest = components.dropFirst().map { $0.capitalized }
    let finalComponents = [vendor.uppercased()] + capitalizedRest

    return finalComponents.joined(separator: " ")
  }
}
