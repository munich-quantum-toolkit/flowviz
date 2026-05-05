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
        VStack(alignment: .leading, spacing: 24) {
            Text("Device Information")
                .font(.title2.bold())

            HStack {
                DashboardCard(title: deviceData.formattedDeviceName) {
                    FlowLayout(spacing: 8) {
                        ForEach(deviceData.nativeGates, id: \.self) { gate in
                            BoxedText(text: gate.uppercased())
                        }
                    }
                }
                .frame(width: 400)

                Spacer()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.grayBackground.ignoresSafeArea()
        DeviceOverview(deviceData: CompilationTrace.previewMock.device)
            .padding()
    }
}
