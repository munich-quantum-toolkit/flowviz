//
//  ChartDataPoint.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 07.05.26.
//

/// Represents a simple chart data point with an integer valued xAxis.
struct ChartDataPoint: Identifiable {
    let step: Int
    let value: Float
    var id: Int { step }
}
