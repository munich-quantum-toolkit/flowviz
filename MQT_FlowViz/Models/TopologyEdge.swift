//
//  TopologyEdge.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//


import Foundation

struct TopologyEdge: Codable, Hashable {
    let control: Int
    let target: Int
}
