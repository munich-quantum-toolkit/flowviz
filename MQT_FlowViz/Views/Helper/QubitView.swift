//
//  QubitView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 04.05.26.
//

import SwiftUI

struct QubitView: View {
    let qubitNumber: String

    var body: some View {
        Text(qubitNumber)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.bluePrimary)
            .padding(8)
            .background(Color.blueBackground)
            .cornerRadius(.greatestFiniteMagnitude)
    }
}

#Preview {
    QubitView(qubitNumber: "00")
        .padding()
}
