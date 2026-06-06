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
    let tentative: Bool
    var id: Int { step }

    init(step: Int, value: Float, tentative: Bool = false) {
        self.step = step
        self.value = value
        self.tentative = tentative
    }
}

/// Represents a logical dataset and stores information relevant for plotting.
struct ChartDataSet: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let data: [ChartDataPoint]
}

/// A single plottable data point containing all the required information for SwiftUI's Chart library.
struct PlottableDataPoint: Identifiable {
    let id = UUID()
    let seriesName: String
    let seriesColor: Color
    let step: Int
    let value: Float
    let tentative: Bool
    var symbolState: String { tentative ? "Tentative" : "Final" }
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
                    tentative: point.tentative
                )
            }
        }
    }
}
