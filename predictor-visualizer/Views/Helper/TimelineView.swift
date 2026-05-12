import SwiftUI

struct TimelineView: View {
    let sequences: [TimelineSequence]

    let rowHeight: CGFloat = 44
    let rowSpacing: CGFloat = 20
    let innerPillHeight: CGFloat = 32

    var totalSteps: Int {
        let absoluteMax = sequences.compactMap { $0.maxStep }.max() ?? -1
        return absoluteMax + 1
    }

    func activeRow(for step: Int) -> Int {
        return sequences.firstIndex(where: { $0.contains(step: step) }) ?? 0
    }

    var body: some View {
        ZStack(alignment: .top) {
            // --- BACKGROUND: Horizontal Grey Separators ---
            VStack(spacing: 0) {
                // Only draw separators if we have more than 1 phase
                if sequences.count > 1 {
                    ForEach(0..<sequences.count - 1, id: \.self) { index in
                        // The first gap gets the initial top-offset.
                        // Every subsequent gap is pushed down by exactly one full row height + spacing.
                        Color.clear.frame(height: index == 0 ? (rowHeight + (rowSpacing / 2)) : (rowHeight + rowSpacing))
                        Divider().background(Color.gray.opacity(0.3))
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

                // --- RIGHT COLUMN (SCROLLABLE) ---
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(0..<totalSteps, id: \.self) { step in
                            // The colored bubble
                            StepColumn(
                                step: step,
                                sequences: sequences,
                                rowHeight: rowHeight,
                                rowSpacing: rowSpacing,
                                pillHeight: innerPillHeight
                            )

                            // The connecting dashed lines
                            if step < totalSteps - 1 {
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
            // Loop through every single phase (row) from top to bottom
            ForEach(sequences) { phase in
                // Check if this specific phase contains our current step
                let isActive = phase.contains(step: step)

                if isActive {
                    BoxedTextView(text: "\(step)", backgroundColor: phase.backgroundColor, textColor: phase.textColor)
                        // enforce strict row height for grid alignment
                        .frame(height: rowHeight)
                } else {
                    // Use invisible spacer to prevent the column from collapsing
                    Color.clear
                        .frame(height: rowHeight)
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
            // Loop through every single phase (row)
            ForEach(sequences) { phase in
                // Check if BOTH adjacent steps are active in this specific phase
                let currentActive = phase.contains(step: currentStep)
                let nextActive = phase.contains(step: nextStep)

                if currentActive && nextActive {
                    // Draw the connecting dashed line
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundColor(phase.textColor.opacity(0.5))
                        .frame(height: 2)
                        .frame(height: rowHeight)
                } else {
                    // Again use invisible spacer
                    Color.clear
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
            title: "✓ Synthesized ✕ Mapped",
            stepRanges: [3...11, 19...20],
            backgroundColor: Color.yellow.opacity(0.3),
            textColor: .orange
        ),
        TimelineSequence(
            title: "✓ Synthesized ✓ Mapped",
            stepRanges: [12...15, 21...25],
            backgroundColor: Color.green.opacity(0.2),
            textColor: .green
        ),
        TimelineSequence(
            title: "✓ Synthesized ✓ Mapped",
            stepRanges: [12...15, 21...25],
            backgroundColor: Color.green.opacity(0.2),
            textColor: .green
        )
    ]

    ZStack {
        Color(white: 0.96).ignoresSafeArea()
        TimelineView(sequences: mockSequences)
            .padding()
            .background(Color.white)
    }
}
