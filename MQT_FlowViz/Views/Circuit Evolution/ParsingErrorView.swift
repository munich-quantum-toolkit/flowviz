//
//  ParsingErrorView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 06.06.26.
//

import SwiftUI

struct ParsingErrorView: View {
    let error: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "stethoscope")
                .font(.largeTitle)
                .foregroundColor(.redPrimary)
            Text("Parsing Failed")
                .font(.body.weight(.semibold))
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

#Preview {
    ParsingErrorView(error: "[GATE] - No qubits found in gate: cx, in line: cx;")
}
