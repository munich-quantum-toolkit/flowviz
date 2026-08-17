//
//  IconizedRowView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 13.06.26.
//

import SwiftUI

struct IconizedRowView<DetailContent: View>: View {
  let icon: String
  let title: String
  let detailContentView: DetailContent

  init(icon: String, title: String, detailContentView: DetailContent) {
    self.icon = icon
    self.title = title
    self.detailContentView = detailContentView
  }

  init(icon: String, title: String, @ViewBuilder detailViewBuilder: () -> DetailContent) {
    self.icon = icon
    self.title = title
    self.detailContentView = detailViewBuilder()
  }

  init(icon: String, title: String, detailText: String) where DetailContent == Text {
    self.icon = icon
    self.title = title
    self.detailContentView = {
      Text(detailText)
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
    }()
  }

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.body.weight(.semibold))
        .frame(width: 20)
        .symbolRenderingMode(.monochrome)

      Text(title)
        .font(.subheadline.weight(.medium))

      Spacer()

      detailContentView
    }
    .foregroundStyle(Color.bluePrimary)
    .padding(.vertical, 12)
  }
}

#Preview {
  IconizedRowView(
    icon: "checkmark.seal",
    title: "Estimated Success",
    detailText: "0.32"
  )
  .padding()
}
