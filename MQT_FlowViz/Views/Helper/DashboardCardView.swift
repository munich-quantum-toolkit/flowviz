//
//  DashboardCardView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//


import SwiftUI

struct DashboardCardView<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        // Tonal Contrast: Pure white card
        .background(.white)
        .cornerRadius(12)
        // Subtle Stroke: 1pt faint gray border
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        // The depressed background color for the whole screen
        Color(.grayBackground).ignoresSafeArea()

        VStack(spacing: 24) {
            DashboardCardView(title: "Device Information") {
                Text("ibm_falcon_127")
                    .foregroundColor(.secondary)
            }
            
            DashboardCardView {
                Text("A card without a title just for metrics.")
            }
        }
        .padding()
    }
}
