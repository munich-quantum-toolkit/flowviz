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
    let seriesData: [ChartDataSet]
    @Binding var selectedStep: Int?

    let chartDomain: [String]
    let chartColorRange: [Color]
    let chartMaxValue: Float
    let chartMinValue: Float

    init(title: String, seriesData: [ChartDataSet], selectedStep: Binding<Int?> = .constant(nil)) {
        self.title = title
        self.seriesData = seriesData
        self._selectedStep = selectedStep

        self.chartDomain = seriesData.map { $0.name }
        self.chartColorRange = seriesData.map { $0.color }
        self.chartMaxValue = seriesData.flatMap { $0.data }.map { $0.value }.max() ?? 1.0
        self.chartMinValue = seriesData.flatMap { $0.data }.map { $0.value }.min() ?? 0.0
    }

    init(title: String, chartData: [ChartDataPoint], chartColor: Color, selectedStep: Binding<Int?> = .constant(nil)) {
        // Note: This initializer is just for plotting a single dataset. The chart will not display a legend, which is why
        // the name value passed to the initializer of ChartDataSet does not have any effect.
        self.init(title: title, seriesData: [ChartDataSet(name: title, color: chartColor, data: chartData)], selectedStep: selectedStep)
    }

    var body: some View {
        DashboardCardView(title: title) {
            Chart {
                ForEach(seriesData) { series in
                    ForEach(series.data) { dataPoint in
                        LineMark(
                            x: .value("Step", dataPoint.step),
                            y: .value("Value", dataPoint.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Series", series.name))

                        PointMark(
                            x: .value("Step", dataPoint.step),
                            y: .value("Value", dataPoint.value)
                        )
                        .symbol {
                            Circle()
                                .fill(dataPoint.tentative ? Color.white : series.color)
                                .strokeBorder(series.color, lineWidth: 2)
                                .frame(width: 9, height: 9)
                        }
                        .foregroundStyle(by: .value("Series", series.name))
                    }
                }

                // Tooltip for selected step
                if let step = selectedStep {
                    // Layer 1: visible dashed line
                    RuleMark(
                        x: .value("Selected Step", step)
                    )
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .zIndex(-1)

                    // Collision Avoidance Logic
                    let currentData = activeData(for: step)
                    let stepMax = currentData.map { $0.value }.max() ?? 0
                    let stepMin = currentData.map { $0.value }.min() ?? 0
                    let stepMidpoint = (stepMax + stepMin) / 2.0

                    // Find the midpoint across all datasets of this chart
                    let chartMidpoint = (self.chartMaxValue + self.chartMinValue) / 2.0

                    // If the data is in the top half, anchor to the bottom and vice versa
                    let isUpperHalf = stepMidpoint > chartMidpoint
                    let anchorY = isUpperHalf ? self.chartMinValue : self.chartMaxValue
                    let anchorPosition: AnnotationPosition = isUpperHalf ? .top : .bottom

                    // Layer 2: invisible anchor for the tooltip
                    // This is a bit hacky since we want the label to be inside the chart.
                    // Theoretically, one could also move the tooltip outside of the chart, but then the boxes
                    // are not as tidy and neat anymore.
                    PointMark(
                        x: .value("Selected Step", step),
                        y: .value("Anchor", anchorY)
                    )
                    .foregroundStyle(.clear)
                    .zIndex(100)
                    .annotation(
                        position: anchorPosition,
                        spacing: 8,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(currentData, id: \.name) { item in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(item.tentative ? Color.white : item.color)
                                        .strokeBorder(item.color, lineWidth: 2)
                                        .frame(width: 8, height: 8)

                                    Text(String(format: "%.2f", item.value))
                                        .font(.footnote.bold())
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .chartForegroundStyleScale(domain: chartDomain, range: chartColorRange)
            .chartLegend(seriesData.count > 1 ? .visible : .hidden)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartXAxis {
                AxisMarks(preset: .aligned, values: .stride(by: 1))
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 8)
            .chartXScale(range: .plotDimension(startPadding: 6, endPadding: 24))
            .chartYScale(range: .plotDimension(padding: 12))
            .chartXSelection(value: $selectedStep)
        }
    }

    /// Extracts the values for the selected step across all datasets.
    private func activeData(for step: Int) -> [(name: String, color: Color, value: Float, tentative: Bool)] {
        seriesData.compactMap { series in
            if let point = series.data.first(where: { $0.step == step }) {
                return (series.name, series.color, point.value, tentative: point.tentative)
            }
            return nil
        }
    }
}

#Preview {
    @Previewable @State var selectedStep: Int? = 5

    let mockData1: [ChartDataPoint] = [
        ChartDataPoint(step: 0, value: 0.25),
        ChartDataPoint(step: 1, value: 0.5),
        ChartDataPoint(step: 2, value: 0.75),
        ChartDataPoint(step: 3, value: 1.0),
        ChartDataPoint(step: 4, value: 0.8),
        ChartDataPoint(step: 5, value: 0.6),
        ChartDataPoint(step: 6, value: 0.9)
    ]

    let mockData2: [ChartDataPoint] = [
        ChartDataPoint(step: 0, value: 0.1),
        ChartDataPoint(step: 1, value: 0.2),
        ChartDataPoint(step: 2, value: 0.3),
        ChartDataPoint(step: 3, value: 0.8),
        ChartDataPoint(step: 4, value: 0.9),
        ChartDataPoint(step: 5, value: 0.5),
        ChartDataPoint(step: 6, value: 0.4)
    ]

    ZStack {
        Color(white: 0.96).ignoresSafeArea()

        GraphBoxView(
            title: "Algorithm Comparison",
            seriesData: [
                ChartDataSet(name: "SABRE", color: .red, data: mockData1),
                ChartDataSet(name: "Qiskit", color: .blue, data: mockData2)
            ],
            selectedStep: $selectedStep
        )
        .frame(width: 400, height: 400)
        .padding()
    }
}
