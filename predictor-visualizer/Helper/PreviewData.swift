//
//  PreviewData.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//

import Foundation

extension CompilationTrace {
    /// A static mock trace loaded directly from the JSON file for SwiftUI Previews.
    static var previewMock: CompilationTrace {
        // 1. Locate the file in the Xcode bundle
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "json") else {
            fatalError("Could not find sample.json in the project bundle. Make sure it is included in the project.")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(CompilationTrace.self, from: data)
        } catch {
            fatalError("Failed to decode preview mock JSON: \(error)")
        }
    }
}
