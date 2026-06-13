//
//  ResultRowView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 13.06.26.
//

import SwiftUI

struct ResultRowView: View {
    let icon: String
    let title: String
    let valueText: String

    // Optional Gauge parameters
    var gaugeValue: Double? = nil
    var gaugeColors: (stroke: Color, background: Color) = (.bluePrimary, .blueBackground)

    @State private var animatedValue: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))

            Text(title)
                .font(.subheadline.weight(.medium))

            Spacer()

            // Inject the tiny animated gauge if a value was provided
            if let targetValue = gaugeValue {
                ZStack {
                    Circle()
                        .stroke(gaugeColors.background, lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: CGFloat(animatedValue))
                        .stroke(gaugeColors.stroke, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 16, height: 16)
                .onAppear {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.1)) {
                        animatedValue = targetValue
                    }
                }
            }

            Text(valueText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(Color.bluePrimary)
        .padding(.vertical, 12)
    }
}

#Preview {
    ResultRowView(
        icon: "checkmark.seal",
        title: "Estimated Success",
        valueText: "0.22",
        gaugeValue: 0.22,
    )}
