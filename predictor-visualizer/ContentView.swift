//
//  ContentView.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var dataHandler = DataHandler()
    @State private var selectedTrace: CompilationTrace?
    @State private var isShowingFilePicker = false
    
    var body: some View {
        NavigationSplitView {
            NavigationListView(traces: dataHandler.traces, selectedTrace: $selectedTrace, isShowingFilePicker: $isShowingFilePicker)
        } detail: {
            if let selected = selectedTrace {
                NavigationDetailView(trace: selected)
            } else {
                PlaceholderView()
            }
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    fileprivate func handleFileSelection(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                try? dataHandler.importTrace(from: selectedURL)
            }
        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
