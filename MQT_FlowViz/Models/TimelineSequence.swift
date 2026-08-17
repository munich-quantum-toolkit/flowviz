//
//  TimelineSequence.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 12.05.26.
//
import SwiftUI

/// Represents a timeline sequence.
struct TimelineSequence: Identifiable {
  let id = UUID()

  let title: String
  let stepRanges: [ClosedRange<Int>]

  let backgroundColor: Color
  let textColor: Color

  var dotmarkHelpText: String? = nil
  var dotmarkColor: Color? = nil

  /// The total number of steps across all ranges.
  var countLabel: String {
    let totalSteps = stepRanges.reduce(0) { $0 + $1.count }
    return "\(totalSteps)x"
  }

  /// Helper function to check if a specific step exists in any of this timeline's ranges.
  func contains(step: Int) -> Bool {
    stepRanges.contains { $0.contains(step) }
  }

  /// Helper to find the absolute highest step number in this timeline.
  var maxStep: Int? {
    stepRanges.map { $0.upperBound }.max()
  }

  /// Helper to find the absolute lowest step number in this timeline.
  var minStep: Int? {
    stepRanges.map { $0.lowerBound }.min()
  }
}
