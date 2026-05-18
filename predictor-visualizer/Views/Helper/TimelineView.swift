//
//  TimelineView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 12.05.26.
//
import SwiftUI

struct TimelineView: View {
    let sequences: [TimelineSequence]

    let rowHeight: CGFloat = 44
    let rowSpacing: CGFloat = 20
    let innerPillHeight: CGFloat = 32

    let startingStep: Int
    let endingStep: Int

    init(sequences: [TimelineSequence]) {
        self.sequences = sequences
        self.startingStep = sequences.compactMap { $0.minStep }.min() ?? 0
        self.endingStep = sequences.compactMap { $0.maxStep }.max() ?? 0
    }

    var body: some View {
        ZStack(alignment: .top) {
            // --- BACKGROUND: Horizontal Grey Separators ---
            VStack(spacing: rowSpacing) {
                ForEach(0..<sequences.count, id: \.self) { index in
                    // Create an invisible block that identically matches the foreground row height and place the divider as overlay
                    Color.clear
                        .frame(height: rowHeight)
                        .overlay(alignment: .bottom) {
                            if index < sequences.count - 1 {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 1)
                                    .offset(y: (rowSpacing / 2) + 0.5)
                            }
                        }
                }
            }

            // --- FOREGROUND: The Content ---
            HStack(alignment: .top, spacing: 16) {
                // --- LEFT COLUMN (STAYS FIXED) ---
                VStack(alignment: .trailing, spacing: rowSpacing) {
                    ForEach(sequences) { phase in
                        StateBadge(
                            title: phase.title,
                            count: phase.countLabel,
                            color: phase.backgroundColor,
                            textColor: phase.textColor,
                            pillHeight: innerPillHeight
                        )
                        .frame(height: rowHeight)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .drawingGroup()

                // --- RIGHT COLUMN (SCROLLABLE) ---
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(startingStep...endingStep, id: \.self) { step in
                            // The colored BoxedTextView
                            StepColumn(
                                step: step,
                                sequences: sequences,
                                rowHeight: rowHeight,
                                rowSpacing: rowSpacing,
                                pillHeight: innerPillHeight
                            )

                            // The connecting dashed lines
                            if step < endingStep {
                                StepSeparator(
                                    currentStep: step,
                                    nextStep: step + 1,
                                    sequences: sequences,
                                    rowHeight: rowHeight,
                                    rowSpacing: rowSpacing
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }
}

// MARK: - Subcomponents

struct StepColumn: View {
    let step: Int
    let sequences: [TimelineSequence]
    let rowHeight: CGFloat
    let rowSpacing: CGFloat
    let pillHeight: CGFloat

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(sequences) { phase in
                let isActive = phase.contains(step: step)

                if isActive {
                    BoxedTextView(text: "\(step)", backgroundColor: phase.backgroundColor, textColor: phase.textColor)
                        .frame(width: 36, height: pillHeight) // Ensure consistent width
                        .frame(height: rowHeight)
                } else {
                    if let min = phase.minStep, let max = phase.maxStep, step >= min && step <= max {
                        Line()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 6], dashPhase: 4))
                            .foregroundColor(phase.textColor.opacity(0.5))
                            .frame(width: 36, height: 2) // Explicit width prevents collapsing
                            .frame(height: rowHeight)
                    } else {
                        Line()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 6], dashPhase: 4))
                            .foregroundColor(Color.gray.opacity(0.3))
                            .frame(width: 36, height: 2)
                            .frame(height: rowHeight)
                    }
                }
            }
        }
    }
}

struct StepSeparator: View {
    let currentStep: Int
    let nextStep: Int
    let sequences: [TimelineSequence]
    let rowHeight: CGFloat
    let rowSpacing: CGFloat

    var body: some View {
        VStack(spacing: rowSpacing) {
            ForEach(sequences) { phase in

                if let min = phase.minStep, let max = phase.maxStep, currentStep >= min && nextStep <= max {
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 6], dashPhase: 0))
                        .foregroundColor(phase.textColor.opacity(0.5))
                        .frame(height: 2)
                        .frame(height: rowHeight)
                } else {
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 6], dashPhase: 0))
                        .foregroundColor(Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(height: rowHeight)
                }
            }
        }
        .frame(width: 24)
    }
}

struct StateBadge: View {
    let title: String
    let count: String
    let color: Color
    let textColor: Color
    let pillHeight: CGFloat

    var body: some View {
        HStack {
            BoxedTextView(text: title, backgroundColor: color, textColor: textColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(count)
                .font(.caption.bold())
                .foregroundStyle(Color.gray.opacity(0.8))
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

#Preview {
    let mockSequences: [TimelineSequence] = [
        TimelineSequence(
            title: "✕ Synthesized ✕ Mapped",
            stepRanges: [0...3, 16...18], // State returns later!
            backgroundColor: Color.red.opacity(0.2),
            textColor: .red
        ),
        TimelineSequence(
            title: "✓ Synthesized",
            stepRanges: [3...11, 19...20],
            backgroundColor: Color.yellow.opacity(0.3),
            textColor: .orange
        ),
        TimelineSequence(
            title: "✓ Mapped",
            stepRanges: [12...15, 21...25],
            backgroundColor: Color.green.opacity(0.2),
            textColor: .green
        )
    ]

    ZStack {
        // NOTE: LazyHStack causes issues in the preview, but works fine in the simulator! Temporarily replace LazyHStack in Line 64 with HStack if you're developing using only the preview here.
        Color(white: 0.96).ignoresSafeArea()
        TimelineView(sequences: mockSequences)
            .padding()
            .background(Color.white)
    }
}
