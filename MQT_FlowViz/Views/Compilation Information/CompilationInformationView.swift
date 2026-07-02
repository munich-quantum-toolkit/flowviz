//
//  CompilationInformationView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 07.05.26.
//
import SwiftUI

struct CompilationInformationView: View {
    let trace: CompilationTrace

    @State private var parallelismData: [ChartDataPoint] = []
    @State private var entanglementData: [ChartDataPoint] = []
    @State private var livenessData: [ChartDataPoint] = []
    @State private var qubitsData: [ChartDataPoint] = []
    @State private var rewardData: [ChartDataPoint] = []
    @State private var depthData: [ChartDataPoint] = []
    @State private var figureOfMeritSeries: [ChartDataSet] = []

    let gridLayout = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Compilation Information")
                .font(.title2.bold())

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    GraphBoxView(title: "Parallelism", chartData: parallelismData, chartColor: Color.bluePrimary)
                        .aspectRatio(1, contentMode: .fit)

                    GraphBoxView(title: "Entanglement Ratio", chartData: entanglementData, chartColor: Color.bluePrimary)
                        .aspectRatio(1, contentMode: .fit)

                    GraphBoxView(title: "Liveness", chartData: livenessData, chartColor: Color.bluePrimary)
                        .aspectRatio(1, contentMode: .fit)
                }

                HStack(spacing: 16) {
                    GraphBoxView(title: "Used Qubits", chartData: qubitsData, chartColor: Color.bluePrimary)
                        .aspectRatio(1, contentMode: .fit)

                    GraphBoxView(title: "RL Reward", chartData: rewardData, chartColor: Color.bluePrimary)
                        .aspectRatio(1, contentMode: .fit)

                    GraphBoxView(title: "Critical Depth", chartData: depthData, chartColor: Color.bluePrimary)
                        .aspectRatio(1, contentMode: .fit)
                }
            }

            GraphBoxView(
                title: "Figures of Merit",
                seriesData: figureOfMeritSeries,
            )
            .aspectRatio(3.1, contentMode: .fit)
        }
        .task(id: trace.id) {
            parallelismData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.parallelism)) }
            entanglementData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.entanglementRatio)) }
            livenessData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.liveness)) }
            qubitsData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.numQubits)) }
            rewardData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.reward)) }
            depthData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.rawCriticalDepth)) }

            var tempExpectedFidelity: [ChartDataPoint] = []
            var tempCriticalDepth: [ChartDataPoint] = []
            var tempHellingerDistance: [ChartDataPoint?] = []
            var tempEstimatedSuccessProbability: [ChartDataPoint?] = []

            let count = trace.steps.count
            tempExpectedFidelity.reserveCapacity(count)
            tempCriticalDepth.reserveCapacity(count)
            tempHellingerDistance.reserveCapacity(count)
            tempEstimatedSuccessProbability.reserveCapacity(count)

            for step in trace.steps {
                let index = step.stepIndex

                let fidelity = step.figuresOfMerit.expectedFidelity
                tempExpectedFidelity.append(ChartDataPoint(step: index, value: Float(fidelity.value), tentative: fidelity.tentative, unavailable: fidelity.unavailable))

                let criticalDepth = step.figuresOfMerit.criticalDepth
                tempCriticalDepth.append(ChartDataPoint(step: index, value: Float(criticalDepth.value), tentative: criticalDepth.tentative, unavailable: criticalDepth.unavailable))

                if let hellingerDistance = step.figuresOfMerit.hellingerDistance {
                    tempHellingerDistance.append(ChartDataPoint(step: index, value: Float(hellingerDistance.value), tentative: hellingerDistance.tentative, unavailable: hellingerDistance.unavailable))
                } else {
                    tempHellingerDistance.append(nil)
                }

                if let esp = step.figuresOfMerit.successProbability {
                    tempEstimatedSuccessProbability.append(ChartDataPoint(step: index, value: Float(esp.value), tentative: esp.tentative, unavailable: esp.unavailable))
                } else {
                    tempEstimatedSuccessProbability.append(nil)
                }
            }

            var tempFOMSeries = [
                ChartDataSet(name: "Expected Fidelity", color: Color.bluePrimary, data: tempExpectedFidelity),
                ChartDataSet(name: "Critical Depth", color: Color.redPrimary, data: tempCriticalDepth),
            ]

            // Ensure Hellinger & ESP are only displayed when the data is actually available
            let filteredHellinger = tempHellingerDistance.compactMap(\.self)
            let filteredESP = tempEstimatedSuccessProbability.compactMap(\.self)

            if filteredHellinger.count == count {
                tempFOMSeries.append(ChartDataSet(name: "Hellinger Distance", color: Color.yellowPrimary, data: tempHellingerDistance.compactMap(\.self)))
            }

            if filteredESP.count == count {
                tempFOMSeries.append(ChartDataSet(name: "Estimated Success Probability", color: Color.greenPrimary, data: tempEstimatedSuccessProbability.compactMap(\.self)))
            }

            figureOfMeritSeries = tempFOMSeries
        }
    }
}

#Preview {
    ZStack {
        Color(white: 0.96).ignoresSafeArea()
        ScrollView {
            CompilationInformationView(trace: CompilationTrace.previewMock)
                .padding()
        }
    }
}
