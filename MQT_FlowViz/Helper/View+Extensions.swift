//
//  View+Extensions.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.05.26.
//
import SwiftUI

extension View {
    /// Ensures first responder status is resigned upon click on the view.
    func hideKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                #if os(iOS)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                #elseif os(macOS)
                NSApplication.shared.keyWindow?.makeFirstResponder(nil)
                #endif
            }
        )
    }
}
