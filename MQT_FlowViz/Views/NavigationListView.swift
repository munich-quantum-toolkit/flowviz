//
//  NavigationListView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//

import SwiftData
import SwiftUI

struct NavigationListView: View {
  @Query(sort: \CompilationTrace.circuitName) private var traces: [CompilationTrace]
  @State private var searchText: String = ""
  @Binding var selectedTrace: CompilationTrace?
  @Binding var isShowingFilePicker: Bool

  @Environment(\.modelContext) private var modelContext

  var filteredTraces: [CompilationTrace] {
    if searchText.isEmpty {
      return traces
    } else {
      return traces.filter { trace in
        trace.circuitName.localizedCaseInsensitiveContains(searchText)
          || trace.device.name.localizedCaseInsensitiveContains(searchText)
      }
    }
  }

  var body: some View {
    List(selection: $selectedTrace) {
      ForEach(filteredTraces) { trace in
        NavigationLink(value: trace) {
          ListItemView(trace: trace)
        }
      }
      .onDelete(perform: deleteTraces)
    }
    #if os(macOS)
      .onDeleteCommand {
        if let traceToDelete = selectedTrace,
          let index = filteredTraces.firstIndex(of: traceToDelete)
        {
          delete(at: index)
        }
      }
    #endif
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

  // MARK: - Deletion Helpers

  private func deleteTraces(offsets: IndexSet) {
    // Sort descending so deleting multiple doesn't shift the indices of yet-to-be-deleted items
    for index in offsets.sorted(by: >) {
      delete(at: index)
    }
  }

  private func delete(at index: Int) {
    let traceToDelete = filteredTraces[index]

    // Only shift selection if the user is deleting the item they are currently viewing
    if traceToDelete == selectedTrace {
      if filteredTraces.count > 1 {
        let nextIndex = (index < filteredTraces.count - 1) ? index + 1 : index - 1
        selectedTrace = filteredTraces[nextIndex]
      } else {
        selectedTrace = nil
      }
    }

    modelContext.delete(traceToDelete)
    try? modelContext.save()
  }
}

#Preview {
  @Previewable @State var selectedTrace: CompilationTrace?
  NavigationSplitView {
    NavigationListView(selectedTrace: $selectedTrace, isShowingFilePicker: .constant(false))
  } detail: {
    PlaceholderView()
  }
}
