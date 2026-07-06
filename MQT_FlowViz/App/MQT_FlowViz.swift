//
//  MQT_FlowViz.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//

import SwiftUI
import SwiftData

@main
struct MQT_FlowViz: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: CompilationTrace.self)
    }
}

