//
//  FlowLayout.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 05.05.26.
//


import SwiftUI

/// A custom layout that flows views horizontally and wraps to the next line.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let boundsWidth = proposal.replacingUnspecifiedDimensions().width
        return computeLayout(boundsWidth: boundsWidth, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = computeLayout(boundsWidth: bounds.width, subviews: subviews).frames
        for (index, subview) in subviews.enumerated() {
            let frame = frames[index]
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
    
    /// Calculates the layout with respect to the provided width and subviews.
    /// - Parameters:
    ///   - boundsWidth: The width that should be used for the calculation.
    ///   - subviews: The subviews that need to be placed.
    /// - Returns: The individual subviews' frames and the total layout size.
    private func computeLayout(boundsWidth: CGFloat, subviews: Subviews) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var currentPoint: CGPoint = .zero
        var rowHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let dimensions = subview.dimensions(in: .unspecified)
            
            // If the item doesn't fit on this line, wrap down to the next row
            if currentPoint.x + dimensions.width > boundsWidth, currentPoint.x > 0 {
                currentPoint.x = 0
                currentPoint.y += rowHeight + spacing
                rowHeight = 0
            }

            let frame = CGRect(origin: currentPoint, size: CGSize(width: dimensions.width, height: dimensions.height))
            frames.append(frame)

            currentPoint.x += dimensions.width + spacing
            rowHeight = max(rowHeight, dimensions.height)
            maxRowWidth = max(maxRowWidth, currentPoint.x - spacing) // Remove trailing spacing
        }

        let totalSize = CGSize(width: maxRowWidth, height: currentPoint.y + rowHeight)
        return (frames, totalSize)
    }
}
