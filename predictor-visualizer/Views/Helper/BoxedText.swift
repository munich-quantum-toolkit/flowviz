//
//  BoxedText.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 04.05.26.
//

import SwiftUI

struct BoxedText: View {
    let gateText: String
    let backgroundColor: Color
    let textColor: Color

    init(gateText: String, backgroundColor: Color = Color.blueBackground, textColor: Color = Color.bluePrimary) {
        self.gateText = gateText
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }

    var body: some View {
        Text(gateText)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.bluePrimary)
            .padding(8)
            .background(Color.blueBackground)
            .cornerRadius(8)
    }
}

#Preview {
    BoxedText(gateText: "RZ(-0.634)")
        .padding()
}
