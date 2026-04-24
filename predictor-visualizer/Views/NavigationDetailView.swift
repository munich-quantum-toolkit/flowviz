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
        Text("You selected: \(trace.circuitName)")
            .font(.largeTitle)
    }
}

#Preview {
    NavigationDetailView(trace: CompilationTrace.previewMock)
}
