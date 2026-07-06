//
//  DashboardCardView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//


import SwiftUI

struct DashboardCardView<Content: View>: View {
    let title: String?
    let dotmarkColor: Color?
    let dotmarkHelpText: String?
    let content: Content

    @State private var showActionTooltip: Bool = false

    init(title: String? = nil, dotmarkColor: Color? = nil, dotmarkHelpText: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.dotmarkColor = dotmarkColor
        self.dotmarkHelpText = dotmarkHelpText
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                HStack(spacing: 8) {
                    if let markColor = dotmarkColor, let helpText = dotmarkHelpText {
                        Circle()
                            .fill(markColor)
                            .frame(width: 7, height: 7)
                            .help(helpText)
                            #if os(iOS)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showActionTooltip.toggle()
                            }
                            .popover(isPresented: $showActionTooltip, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                                Text(helpText)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .presentationCompactAdaptation(.popover) // Forces it to stay a small popover on iPhone/iPad
                            }
                            #endif
                    }
                    Text(title)
                        .font(.callout)
                        .fontWeight(.semibold)
                    

                }
            }
            
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
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
