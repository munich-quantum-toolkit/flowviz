//
//  CompilationTrace.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//

import Foundation
import SwiftUI

struct CompilationTrace: Codable, Hashable, Identifiable {
    let id = UUID()
    
    let circuitName: String
    let figureOfMerit: String
    let mdpPolicy: String
    let device: DeviceMetadata
    let schemaVersion: String
    let timestamp: Double
    let steps: [CompilationStep]
    
    /// Collects the MDP state evolution of the compilation trace.
    /// - Returns: A tuple containing the individual MDP states and the corresponding ranges.
    func getMDPStateEvolution() -> (synthesizedRanges: [ClosedRange<Int>], laidOutRanges: [ClosedRange<Int>], routedRanges: [ClosedRange<Int>]) {
        guard !steps.isEmpty else { return ([], [], []) }

        let sortedSteps = steps.sorted { $0.stepIndex < $1.stepIndex }

        let synthesizedRanges = extractRanges(where: { $0.synthesized }, in: sortedSteps)
        let laidOutRanges = extractRanges(where: { $0.laidOut }, in: sortedSteps)
        let routedRanges = extractRanges(where: { $0.routed }, in: sortedSteps)

        return (synthesizedRanges, laidOutRanges, routedRanges)
    }
    
    /// Extracts ranges from the compilation trace during which a certain condition is fulfilled.
    /// - Parameters:
    ///   - condition: The condition to check for.
    ///   - sortedSteps: An array of sorted compilation steps.
    /// - Returns: Ranges of compilation steps during which the condition is fulfilled.
    private func extractRanges(where condition: (CompilationStep) -> Bool, in sortedSteps: [CompilationStep]) -> [ClosedRange<Int>] {
        var ranges: [ClosedRange<Int>] = []
        var currentStart: Int? = nil
        var previousIndex: Int? = nil

        for step in sortedSteps {
            let isTrue = condition(step)

            let isContiguous: Bool
            if let prev = previousIndex {
                isContiguous = (step.stepIndex == prev + 1)
            } else {
                isContiguous = true
            }

            if isTrue {
                if currentStart == nil {
                    // Start new range
                    currentStart = step.stepIndex
                } else if !isContiguous {
                    // Close the range & start new one
                    if let start = currentStart, let prev = previousIndex {
                        ranges.append(start...prev)
                    }
                    currentStart = step.stepIndex
                }
            } else {
                // Boolean flipped to false, close the active range
                if let start = currentStart, let prev = previousIndex {
                    ranges.append(start...prev)
                    currentStart = nil
                }
            }
            previousIndex = step.stepIndex
        }

        // Close any active range at the end
        if let start = currentStart, let prev = previousIndex {
            ranges.append(start...prev)
        }

        return ranges
    }
}
