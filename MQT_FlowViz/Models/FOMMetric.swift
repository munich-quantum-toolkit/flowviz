//
//  FOMMetric.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//


import Foundation

struct FOMMetric: Codable, Hashable {
    let value: Double
    let kind: String

    var tentative: Bool {
        return kind == "approx"
    }
}
