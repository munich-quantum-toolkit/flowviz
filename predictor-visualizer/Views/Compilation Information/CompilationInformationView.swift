//
//  CompilationInformationView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 07.05.26.
//
import SwiftUI

struct CompilationInformationView: View {
    let trace: CompilationTrace

    @State private var selectedStep: Int? = nil

    @State private var parallelismData: [ChartDataPoint] = []
    @State private var entanglementData: [ChartDataPoint] = []
    @State private var livenessData: [ChartDataPoint] = []
    @State private var qubitsData: [ChartDataPoint] = []
    @State private var rewardData: [ChartDataPoint] = []
    @State private var depthData: [ChartDataPoint] = []

    let gridLayout = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Compilation Information")
                .font(.title2.bold())

            LazyVGrid(columns: gridLayout, spacing: 16) {
                GraphBoxView(
                    title: "Parallelism",
                    chartData: parallelismData,
                    chartColor: Color.bluePrimary,
                    selectedStep: $selectedStep
                )
                .aspectRatio(1, contentMode: .fit)

                GraphBoxView(
                    title: "Entanglement Ratio",
                    chartData: entanglementData,
                    chartColor: Color.bluePrimary,
                    selectedStep: $selectedStep
                )
                .aspectRatio(1, contentMode: .fit)

                GraphBoxView(
                    title: "Liveness",
                    chartData: livenessData,
                    chartColor: Color.bluePrimary,
                    selectedStep: $selectedStep
                )
                .aspectRatio(1, contentMode: .fit)

                GraphBoxView(
                    title: "Used Qubits",
                    chartData: qubitsData,
                    chartColor: Color.bluePrimary,
                    selectedStep: $selectedStep
                )
                .aspectRatio(1, contentMode: .fit)

                GraphBoxView(
                    title: "RL Reward",
                    chartData: rewardData,
                    chartColor: Color.bluePrimary,
                    selectedStep: $selectedStep
                )
                .aspectRatio(1, contentMode: .fit)

                GraphBoxView(
                    title: "Critical Depth",
                    chartData: depthData,
                    chartColor: Color.bluePrimary,
                    selectedStep: $selectedStep
                )
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .task(id: trace.id) {
            parallelismData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.parallelism)) }
            entanglementData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.entanglementRatio)) }
            livenessData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.liveness)) }
            qubitsData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.numQubits)) }
            rewardData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.reward)) }
            depthData = trace.steps.map { ChartDataPoint(step: $0.stepIndex, value: Float($0.rawCriticalDepth)) }
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
