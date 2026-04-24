//
//  CompilationTrace.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//


import Foundation

struct CompilationTrace: Codable, Hashable, Identifiable {
    let id = UUID() // Synthetic ID so SwiftUI can list different traces
    
    let circuitName: String
    let figureOfMerit: String
    let mdpPolicy: String
    let device: DeviceMetadata
    let schemaVersion: String
    let timestamp: Double
    let steps: [CompilationStep]
}
