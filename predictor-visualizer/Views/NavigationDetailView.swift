//
//  NavigationDetailView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//

import SwiftUI

struct NavigationDetailView: View {
    let trace: CompilationTrace

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                DeviceInformationView(deviceData: trace.device)
                CompilationInformationView(trace: trace)
                CompilationPipelineView(trace: trace)
                MDPEvolutionView(trace: trace)
            }
            .padding(EdgeInsets(top: 0, leading: 24, bottom: 24, trailing: 24))
        }
        .clipped()
    }
}

#Preview {
    ZStack {
        Color.grayBackground.ignoresSafeArea()
        NavigationDetailView(trace: CompilationTrace.previewMock)
    }
}
