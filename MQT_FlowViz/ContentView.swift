//
//  ContentView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CompilationTrace.circuitName) private var traces: [CompilationTrace]
    @State private var dataHandler = DataHandler()
    @State private var selectedTrace: CompilationTrace?
    @State private var isShowingFilePicker = false
    
    var body: some View {
        NavigationSplitView {
            NavigationListView(traces: traces, selectedTrace: $selectedTrace, isShowingFilePicker: $isShowingFilePicker)
        } detail: {
            if let selected = selectedTrace {
                NavigationDetailView(trace: selected)
                    .background(Color.grayBackground)
                #if os(macOS)
                    .toolbarBackground(.hidden, for: .windowToolbar)
                #elseif os(iOS)
                    .toolbarVisibility(.hidden, for: .navigationBar)
                #endif
            } else {
                PlaceholderView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.grayBackground)
                    #if os(macOS)
                    .toolbarBackground(.hidden, for: .windowToolbar)
                    #endif
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
                try? dataHandler.importTrace(from: selectedURL, into: modelContext)
            }
        case .failure(let error):
            print("Error selecting file: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
