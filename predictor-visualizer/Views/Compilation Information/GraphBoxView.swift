//
//  GraphBoxView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 05.05.26.
//

import SwiftUI
import Charts

struct GraphBoxView: View {
    let title: String
    let chartData: [ChartDataPoint]
    let chartColor: Color
    @Binding var selectedStep: Int?

    private var selectedDataPoint: ChartDataPoint? {
        if let step = selectedStep {
            return chartData.first { $0.step == step }
        }
        return nil
    }

    var body: some View {
        DashboardCardView(title: title) {
            Chart {
                ForEach(chartData) { dataPoint in
                    LineMark(
                        x: .value("Step", dataPoint.step),
                        y: .value("Value", dataPoint.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(chartColor)

                    PointMark(
                        x: .value("Step", dataPoint.step),
                        y: .value("Value", dataPoint.value)
                    )
                    .symbol {
                        Circle()
                            .fill(selectedStep == dataPoint.step ? chartColor : Color.white)
                            .strokeBorder(chartColor, lineWidth: 2)
                            .frame(width: 12, height: 12)
                    }
                    .annotation(
                        position: .top,
                        spacing: 8,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        if selectedStep == dataPoint.step {
                            Text(String(format: "%.2f", dataPoint.value))
                                .font(.footnote.bold())
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }

                if let selected = selectedDataPoint {
                    RuleMark(
                        x: .value("Selected Step", selected.step)
                    )
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .zIndex(-1)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartXAxis(content: {
                AxisMarks(preset: .aligned, values: .stride(by: 1))
            })
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 10)
            .chartXScale(range: .plotDimension(startPadding: 6, endPadding: 24))
            .chartYScale(range: .plotDimension(padding: 12))
            .chartXSelection(value: $selectedStep)
        }
    }
}

#Preview {
    @Previewable @State var selectedStep: Int? = 1

    let mockData: [ChartDataPoint] = [
        ChartDataPoint(step: 0, value: 0.25),
        ChartDataPoint(step: 1, value: 0.5),
        ChartDataPoint(step: 2, value: 0.75),
        ChartDataPoint(step: 3, value: 1.0),
        ChartDataPoint(step: 4, value: 0.8),
        ChartDataPoint(step: 5, value: 0.6),
        ChartDataPoint(step: 6, value: 0.9),
        ChartDataPoint(step: 7, value: 0.95),
        ChartDataPoint(step: 8, value: 0.85),
        ChartDataPoint(step: 9, value: 0.4),
        ChartDataPoint(step: 10, value: 0.3),
        ChartDataPoint(step: 11, value: 0.5),
        ChartDataPoint(step: 12, value: 0.7)
    ]

    ZStack {
        Color(white: 0.96).ignoresSafeArea()

        GraphBoxView(
            title: "Parallelism",
            chartData: mockData,
            chartColor: Color.redPrimary,
            selectedStep: $selectedStep
        )
        .frame(width: 400, height: 400)
        .padding()
    }
}
