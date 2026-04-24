//
//  NavigationListView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//

import SwiftUI

struct NavigationListView: View {
    let traces: [CompilationTrace]
    @State private var searchText: String = ""
    @Binding var selectedTrace: CompilationTrace?
    @Binding var isShowingFilePicker: Bool

    var filteredTraces: [CompilationTrace] {
        if searchText.isEmpty {
            return traces
        } else {
            return traces.filter { trace in
                trace.circuitName.localizedCaseInsensitiveContains(searchText) ||
                trace.device.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List(filteredTraces, selection: $selectedTrace) { trace in
            NavigationLink(value: trace) {
                ListItemView(trace: trace)
            }
        }
        .navigationTitle("Compilations")
        .searchable(text: $searchText, placement: .sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingFilePicker = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTrace: CompilationTrace?
    NavigationSplitView {
        NavigationListView(traces: [CompilationTrace.previewMock], selectedTrace: $selectedTrace, isShowingFilePicker: .constant(false))
    } detail: {
        PlaceholderView()
    }
}
