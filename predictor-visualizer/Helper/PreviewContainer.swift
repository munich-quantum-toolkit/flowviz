//
//  PreviewContainer.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 28.05.26.
//

import SwiftData

extension ModelContainer {
    @MainActor
    static let previewContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: CompilationTrace.self, configurations: config)
            container.mainContext.insert(CompilationTrace.previewMock)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
}
