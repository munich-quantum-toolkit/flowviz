//
//  DeviceInformationView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 04.05.26.
//
import SwiftUI

struct DeviceInformationView: View {
    let deviceData: DeviceMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Device Information")
                .font(.title2.bold())

            HStack {
                DashboardCardView(title: deviceData.formattedDeviceName) {
                    FlowLayout(spacing: 8) {
                        ForEach(deviceData.nativeGates, id: \.self) { gate in
                            BoxedTextView(text: gate.uppercased())
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
        DeviceInformationView(deviceData: CompilationTrace.previewMock.device)
            .padding()
    }
}
