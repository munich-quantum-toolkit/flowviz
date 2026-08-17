//
//  FooterNoteView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 02.06.26.
//
import SwiftUI

struct FooterNoteView: View {
  let projectURL = URL(string: "https://github.com/munich-quantum-toolkit")!

  var body: some View {
    VStack(spacing: 6) {
      Text("Made with ❤️ and 🥨 in Munich, Bavaria")
        .font(.footnote)
        .fontWeight(.semibold)
        .foregroundStyle(.gray)

      Link(destination: projectURL) {
        Text("Learn more \(Image(systemName: "arrow.right"))")
      }
      .font(.footnote)
      .fontWeight(.semibold)
      .foregroundStyle(.gray)
      .underline()
      .buttonStyle(.plain)
    }
    .frame(maxWidth: .infinity, alignment: .center)
  }
}

#Preview {
  FooterNoteView()
}
