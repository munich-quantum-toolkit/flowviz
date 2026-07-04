//
//  FigureOfMeritMetrics.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//


import Foundation

struct FigureOfMeritMetrics: Codable, Hashable {
    let expectedFidelity: FOMMetric
    let criticalDepth: FOMMetric
    let estimatedHellingerDistance: FOMMetric?
    let estimatedSuccessProbability: FOMMetric?
}
