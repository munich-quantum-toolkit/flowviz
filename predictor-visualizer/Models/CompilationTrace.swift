//
//  CompilationTrace.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class CompilationTrace: Codable, Identifiable {
    @Attribute(.unique) var id: String

    var circuitName: String
    var figureOfMerit: String
    var mdpPolicy: String
    var device: DeviceMetadata
    var schemaVersion: String
    var timestamp: Double
    var steps: [CompilationStep]

    init(id: String, circuitName: String, figureOfMerit: String, mdpPolicy: String, device: DeviceMetadata, schemaVersion: String, timestamp: Double, steps: [CompilationStep]) {
        self.id = id
        self.circuitName = circuitName
        self.figureOfMerit = figureOfMerit
        self.mdpPolicy = mdpPolicy
        self.device = device
        self.schemaVersion = schemaVersion
        self.timestamp = timestamp
        self.steps = steps
    }

    enum CodingKeys: String, CodingKey {
        case id
        case circuitName
        case figureOfMerit
        case mdpPolicy
        case device
        case schemaVersion
        case timestamp
        case steps
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = UUID().uuidString
        self.circuitName = try container.decode(String.self, forKey: .circuitName)
        self.figureOfMerit = try container.decode(String.self, forKey: .figureOfMerit)
        self.mdpPolicy = try container.decode(String.self, forKey: .mdpPolicy)
        self.device = try container.decode(DeviceMetadata.self, forKey: .device)
        self.schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        self.timestamp = try container.decode(Double.self, forKey: .timestamp)
        self.steps = try container.decode([CompilationStep].self, forKey: .steps)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(circuitName, forKey: .circuitName)
        try container.encode(figureOfMerit, forKey: .figureOfMerit)
        try container.encode(mdpPolicy, forKey: .mdpPolicy)
        try container.encode(device, forKey: .device)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(steps, forKey: .steps)
    }

    /// Collects the actions that were applied throughout the compilation.
    /// - Returns: An array of ``TimelineSequence`` values.
    func getActionEvolution() -> [TimelineSequence] {
        guard !steps.isEmpty else { return [] }

        let sortedSteps = steps.sorted { $0.stepIndex < $1.stepIndex }

        var orderedActions: [String] = []
        var seenActions: Set<String> = []

        for step in sortedSteps {
            if !seenActions.contains(step.action) {
                seenActions.insert(step.action)
                orderedActions.append(step.action)
            }
        }

        return orderedActions.enumerated().map { index, actionName in
            let actionRanges = extractRanges(where: { $0.action == actionName }, in: sortedSteps)

            return TimelineSequence(
                title: actionName,
                stepRanges: actionRanges,
                backgroundColor: Color.blueBackground,
                textColor: Color.bluePrimary
            )
        }
    }

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
