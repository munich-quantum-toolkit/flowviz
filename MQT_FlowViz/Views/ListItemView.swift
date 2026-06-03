//
//  ListItemView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//
import SwiftUI

struct ListItemView: View {
    let trace: CompilationTrace

    var compilationDate: String {
        Date(timeIntervalSince1970: trace.timestamp)
            .formatted(date: .numeric, time: .omitted)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trace.circuitName)
                    .font(.headline)
                Text(trace.device.formattedDeviceName + ", " + trace.device.deviceQubits.description + " qubits")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(Color.primary)
        }
    }
}

#Preview {
    ListItemView(trace: CompilationTrace.previewMock)
}

