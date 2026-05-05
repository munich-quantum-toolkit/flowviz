//
//  BoxedText.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 04.05.26.
//

import SwiftUI

struct BoxedText: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color

    init(text: String, backgroundColor: Color = Color.blueBackground, textColor: Color = Color.bluePrimary) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(Color.bluePrimary)
            .padding(8)
            .background(Color.blueBackground)
            .cornerRadius(8)
    }
}

#Preview {
    BoxedText(text: "RZ(-0.634)")
        .padding()
}
