//
//  predictor_visualizerApp.swift
//  predictor-visualizer
//
//  Created by Linus Bohle on 24.04.26.
//

import SwiftUI
import SwiftData

@main
struct predictor_visualizerApp: App {    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: CompilationTrace.self)
    }
}
