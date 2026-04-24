//
//  TopologyEdge.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//


import Foundation

struct TopologyEdge: Codable, Hashable {
    let control: Int
    let target: Int
}
