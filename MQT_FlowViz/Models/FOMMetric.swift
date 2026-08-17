//
//  FOMMetric.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//

import Foundation

/// Defines the three possible evaluation states for a metric.
enum MetricKind: String, Codable, Hashable {
  case exact = "exact"
  case approximate = "approximate"
  case unavailable = "unavailable"

  var displayName: String {
    return self.rawValue.capitalized
    // uncomment below switch if display name varies from raw value in the future
    // switch self {
    // case .exact: return "Exact"
    // case .approximate: return "Approximate"
    // case .unavailable: return "Unavailable"
    // }
  }
}

struct FOMMetric: Codable, Hashable {
  let value: Double
  let kind: MetricKind
}
