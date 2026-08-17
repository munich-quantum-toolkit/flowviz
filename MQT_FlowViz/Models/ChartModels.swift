//
//  ChartModels.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 07.05.26.
//
import SwiftUI

/// Represents a simple chart data point with an integer valued xAxis.
struct ChartDataPoint: Identifiable {
  let step: Int
  let value: Float
  let kind: MetricKind

  var id: Int { step }

  init(step: Int, value: Float, kind: MetricKind = .exact) {
    self.step = step
    self.value = value
    self.kind = kind
  }
}

/// Represents a logical dataset and stores information relevant for plotting.
struct ChartDataSet: Identifiable {
  let name: String
  let color: Color
  let data: [ChartDataPoint]

  var id: String { name }
}

/// A single plottable data point containing all the required information for SwiftUI's Chart library.
struct PlottableDataPoint: Identifiable {
  let seriesName: String
  let seriesColor: Color
  let step: Int
  let value: Float
  let kind: MetricKind

  // Stable ID combining the series name and the step (e.g., "Expected Fidelity-5")
  // This is important for performance, do not use a UUID here since PlottableDataPoints are
  // initialized directly in the init of GraphBoxView.
  var id: String { "\(seriesName)-\(step)" }

  var symbolState: String { kind.rawValue.capitalized }
}

extension Array where Element == ChartDataSet {
  /// Flattens the hierarchical datasets into an optimized 1D array Swift Charts needs.
  func flattenedForPlotting() -> [PlottableDataPoint] {
    self.flatMap { dataset in
      dataset.data.map { point in
        PlottableDataPoint(
          seriesName: dataset.name,
          seriesColor: dataset.color,
          step: point.step,
          value: point.value,
          kind: point.kind
        )
      }
    }
  }
}
