//
//  ChartModels.swift
//  predictor-visualizer
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

/// Represents a plottable dataset.
struct ChartDataSet: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let data: [ChartDataPoint]
}
