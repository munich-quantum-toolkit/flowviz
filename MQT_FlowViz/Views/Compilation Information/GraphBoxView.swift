import Charts
//
//  GraphBoxView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 05.05.26.
//
import SwiftUI

struct GraphBoxView: View {
  let title: String
  let seriesData: [ChartDataSet]
  @State var selectedStep: Int?

  let chartDomain: [String]
  let chartColorRange: [Color]
  let chartMaxValue: Float
  let chartMinValue: Float

  let stepDataMap: [Int: [PlottableDataPoint]]
  let flatData: [PlottableDataPoint]

  init(title: String, seriesData: [ChartDataSet]) {
    self.title = title
    self.seriesData = seriesData

    let flattened = seriesData.flattenedForPlotting()
    self.flatData = flattened

    self.chartDomain = seriesData.map(\.name)
    self.chartColorRange = seriesData.map(\.color)

    let allValues = flattened.map(\.value)
    self.chartMaxValue = allValues.max() ?? 1.0
    self.chartMinValue = allValues.min() ?? 0.0

    self.stepDataMap = Dictionary(grouping: flattened, by: \.step)
  }

  init(title: String, chartData: [ChartDataPoint], chartColor: Color) {
    self.init(
      title: title, seriesData: [ChartDataSet(name: title, color: chartColor, data: chartData)])
  }

  var body: some View {
    DashboardCardView(title: title) {
      Chart {
        LinePlot(
          flatData,
          x: .value("Step", \PlottableDataPoint.step),
          y: .value("Value", \PlottableDataPoint.value),
          series: .value("Series", \PlottableDataPoint.seriesName)
        )
        .foregroundStyle(by: .value("Series", \PlottableDataPoint.seriesName))
        .interpolationMethod(.monotone)

        PointPlot(
          flatData,
          x: .value("Step", \.step),
          y: .value("Value", \.value)
        )
        .foregroundStyle(by: .value("Series", \PlottableDataPoint.seriesName))
        .symbol(by: .value("State", \PlottableDataPoint.symbolState))

        // Tooltip for selected step
        if let step = selectedStep {
          // Layer 1: visible dashed line
          RuleMark(
            x: .value("Selected Step", step)
          )
          .foregroundStyle(Color.gray.opacity(0.5))
          .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
          .zIndex(-1)

          let currentData = stepDataMap[step] ?? []
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
              ForEach(currentData) { item in
                HStack(spacing: 6) {
                  // Differentiate shapes based on state
                  switch item.kind {
                  case .unavailable:
                    BasicChartSymbolShape.cross
                      .fill(item.seriesColor)
                      .frame(width: 8, height: 8)
                  case .approximate:
                    BasicChartSymbolShape.triangle
                      .fill(item.seriesColor)
                      .frame(width: 8, height: 8)
                  case .exact:
                    BasicChartSymbolShape.circle
                      .fill(item.seriesColor)
                      .frame(width: 8, height: 8)
                  }

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
      .chartSymbolScale([
        MetricKind.unavailable.displayName: BasicChartSymbolShape.cross,
        MetricKind.approximate.displayName: BasicChartSymbolShape.triangle,
        MetricKind.exact.displayName: BasicChartSymbolShape.circle,
      ])
      .chartLegend(seriesData.count > 1 ? .visible : .hidden)
      .chartLegend(position: .bottom, alignment: .leading) {
        // Custom legend to prevent Charts library from creating entries for "Tentative" and "Final" as well
        if seriesData.count > 1 {
          HStack(spacing: 16) {
            ForEach(seriesData, id: \.name) { series in
              HStack(spacing: 6) {
                Circle()
                  .fill(series.color)
                  .frame(width: 8, height: 8)

                Text(series.name)
                  .font(.caption)
                  .foregroundStyle(.gray)
              }
            }

            Spacer()

            HStack(spacing: 6) {
              BasicChartSymbolShape.circle
                .fill(Color.gray)
                .frame(width: 8, height: 8)

              Text("Exact")
                .font(.caption)
                .foregroundStyle(.gray)
            }

            HStack(spacing: 6) {
              BasicChartSymbolShape.triangle
                .fill(Color.gray)
                .frame(width: 8, height: 8)

              Text("Approximate")
                .font(.caption)
                .foregroundStyle(.gray)
            }

            HStack(spacing: 6) {
              BasicChartSymbolShape.cross
                .fill(Color.gray)
                .frame(width: 8, height: 8)

              Text("Unavailable")
                .font(.caption)
                .foregroundStyle(.gray)
            }
          }
          .padding(.top, 4)
        }
      }
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
    ChartDataPoint(step: 6, value: 0.9),
  ]

  let mockData2: [ChartDataPoint] = [
    ChartDataPoint(step: 0, value: 0.1),
    ChartDataPoint(step: 1, value: 0.2),
    ChartDataPoint(step: 2, value: 0.3),
    ChartDataPoint(step: 3, value: 0.8),
    ChartDataPoint(step: 4, value: 0.9),
    ChartDataPoint(step: 5, value: 0.5),
    ChartDataPoint(step: 6, value: 0.4),
  ]

  ZStack {
    Color(white: 0.96).ignoresSafeArea()

    GraphBoxView(
      title: "Algorithm Comparison",
      seriesData: [
        ChartDataSet(name: "SABRE", color: .red, data: mockData1),
        ChartDataSet(name: "Qiskit", color: .blue, data: mockData2),
      ]
    )
    .frame(width: 400, height: 400)
    .padding()
  }
}
