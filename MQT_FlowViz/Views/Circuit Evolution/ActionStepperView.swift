//
//  ActionStepperView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 04.06.26.
//
import SwiftUI

struct ActionStepperView: View {
    let totalSteps: Int
    @Binding var currentStep: Int

    @State private var stepInput: Int?
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {

            // --- PREVIOUS BUTTON ---
            Button(action: {
                if currentStep > 0 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep -= 1
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(currentStep > 0 ? .black : .gray.opacity(0.3))
            }
            .buttonStyle(.borderless)
            .disabled(currentStep == 0)

            // --- TEXT INPUT ---
            HStack(spacing: 8) {
                TextField("", value: $stepInput, format: .number.grouping(.never))
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.black)
                    .monospacedDigit()
                    .frame(minWidth: 34)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding([.top, .bottom], 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.tertiary, lineWidth: 1)
                    )
                    .onSubmit {
                        applyManualStepInput()
                        isFocused = false
                    }
                    .onChange(of: isFocused) { _, isNowFocused in
                        if !isNowFocused {
                            applyManualStepInput()
                        }
                    }

                Text("/ \(totalSteps - 1)")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.black)
                    .monospacedDigit()
            }
            .onAppear {
                stepInput = currentStep
            }
            .onChange(of: currentStep) { _, newValue in
                stepInput = newValue
            }

            // --- NEXT BUTTON ---
            Button(action: {
                if currentStep < totalSteps - 1 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep += 1
                    }
                }
            }
            ) {
                Image(systemName: "chevron.right")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(currentStep < totalSteps - 1 ? .black : .gray.opacity(0.3))
            }
            .buttonStyle(.borderless)
            .disabled(currentStep == totalSteps - 1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    /// Helper method that validates and applies the provided step input from the user.
    private func applyManualStepInput() {
        guard let parsed = stepInput else {
            stepInput = currentStep
            return
        }

        let bounded = max(0, min(parsed, totalSteps - 1))

        withAnimation(.easeInOut(duration: 0.2)) {
            currentStep = bounded
        }

        stepInput = bounded
    }
}
