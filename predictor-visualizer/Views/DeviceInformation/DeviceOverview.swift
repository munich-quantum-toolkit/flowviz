//
//  DeviceOverview.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 04.05.26.
//
import SwiftUI

struct DeviceOverview: View {
    let deviceData: DeviceMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Device Information")
                .font(.title2.bold())

            DashboardCard(title: deviceData.formattedDeviceName) {
                FlowLayout(spacing: 8) {
                    ForEach(deviceData.nativeGates, id: \.self) { gate in
                        BoxedText(text: gate.uppercased())
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.grayBackground.ignoresSafeArea()
        DeviceOverview(deviceData: CompilationTrace.previewMock.device)
            .frame(width: 300)
            .padding()
    }
}
