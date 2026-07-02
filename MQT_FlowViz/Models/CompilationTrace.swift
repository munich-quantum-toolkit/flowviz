//
//  CompilationTrace.swift
//  MQT_FlowViz
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
    var totalDuration: Float
    var steps: [CompilationStep]

    init(id: String, circuitName: String, figureOfMerit: String, mdpPolicy: String, device: DeviceMetadata, schemaVersion: String, timestamp: Double, totalDuration: Float, steps: [CompilationStep]) {
        self.id = id
        self.circuitName = circuitName
        self.figureOfMerit = figureOfMerit
        self.mdpPolicy = mdpPolicy
        self.device = device
        self.schemaVersion = schemaVersion
        self.timestamp = timestamp
        self.totalDuration = totalDuration
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
        case totalDuration
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
        self.totalDuration = try container.decode(Float.self, forKey: .totalDuration)
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

        var actionRanges: [String: [ClosedRange<Int>]] = [:]
        var currentStarts: [String: Int] = [:]
        var previousIndices: [String: Int] = [:]
        var orderedActions: [String] = []

        for step in sortedSteps {
            let action = step.actionName

            // Register action on first appearance
            if actionRanges[action] == nil {
                orderedActions.append(action)
                actionRanges[action] = []
            }

            // Extract current range tracking state
            var ranges = actionRanges[action]!
            var start = currentStarts[action]
            var prev = previousIndices[action]

            // Process the step w.r.t. the current action as active
            processStepForRange(isActive: true, stepIndex: step.stepIndex, ranges: &ranges, start: &start, prev: &prev)

            // Save tracking state back to dictionaries
            actionRanges[action] = ranges
            currentStarts[action] = start
            previousIndices[action] = prev
        }

        // Close any remaining open ranges that were still active after reaching the end of the array
        for action in orderedActions {
            var ranges = actionRanges[action]!
            var start = currentStarts[action]
            var prev = previousIndices[action]

            // Setting isActive to false causes the helper to close any active range
            processStepForRange(isActive: false, stepIndex: 0, ranges: &ranges, start: &start, prev: &prev)
            actionRanges[action] = ranges
        }

        return orderedActions.map { action in
            TimelineSequence(
                title: action,
                stepRanges: actionRanges[action] ?? [],
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

        var synRanges: [ClosedRange<Int>] = []
        var laidRanges: [ClosedRange<Int>] = []
        var routRanges: [ClosedRange<Int>] = []

        // The active range trackers
        var synStart: Int? = nil, synPrev: Int? = nil
        var laidStart: Int? = nil, laidPrev: Int? = nil
        var routStart: Int? = nil, routPrev: Int? = nil

        for step in sortedSteps {
            let idx = step.stepIndex
            processStepForRange(isActive: step.synthesized, stepIndex: idx, ranges: &synRanges, start: &synStart, prev: &synPrev)
            processStepForRange(isActive: step.laidOut, stepIndex: idx, ranges: &laidRanges, start: &laidStart, prev: &laidPrev)
            processStepForRange(isActive: step.routed, stepIndex: idx, ranges: &routRanges, start: &routStart, prev: &routPrev)
        }

        // Close any remaining open ranges that were still active after reaching the end of the array
        // Setting isActive to false causes the helper to close any active range
        processStepForRange(isActive: false, stepIndex: 0, ranges: &synRanges, start: &synStart, prev: &synPrev)
        processStepForRange(isActive: false, stepIndex: 0, ranges: &laidRanges, start: &laidStart, prev: &laidPrev)
        processStepForRange(isActive: false, stepIndex: 0, ranges: &routRanges, start: &routStart, prev: &routPrev)

        return (synRanges, laidRanges, routRanges)
    }

    // helper to cleanly process the ranges
    private func processStepForRange(isActive: Bool, stepIndex: Int, ranges: inout [ClosedRange<Int>], start: inout Int?, prev: inout Int?) {
        let isContiguous = (prev == nil) || (stepIndex == prev! + 1)

        if isActive {
            if start == nil {
                start = stepIndex // Open a new range
            } else if !isContiguous {
                // Close old range and open a new one
                ranges.append(start!...prev!)
                start = stepIndex
            }
        } else {
            if let s = start, let p = prev {
                ranges.append(s...p) // Condition turned false, close the active range
                start = nil
            }
        }
        prev = stepIndex
    }
}
