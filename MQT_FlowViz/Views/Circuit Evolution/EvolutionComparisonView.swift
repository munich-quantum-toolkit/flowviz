//
//  EvolutionComparisonView.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 06.06.26.
//
import SwiftUI

struct EvolutionComparisonView: View {
    let trace: CompilationTrace

    @State var currentStep: Int
    @State var comparedStep: Int
    @State var layoutHorizontal: Bool

    @State var isLinked: Bool = false
    @State private var isSyncing: Bool = false

    @State private var currentCircuit: ParsedCircuit? = nil
    @State private var comparedCircuit: ParsedCircuit? = nil

    @State var parseErrorCurrentCircuit: String? = nil
    @State var parseErrorComparedCircuit: String? = nil

    let rowHeight: CGFloat = 40
    let minColumnWidth: CGFloat = 50

    init(trace: CompilationTrace, currentStep: Int) {
        self.trace = trace

        self._currentStep = State(initialValue: currentStep)
        self._layoutHorizontal = State(initialValue: false)

        if currentStep < trace.steps.count - 1 {
            self._comparedStep = currentStep == 0 ? State(initialValue: trace.steps.count - 1) : State(initialValue: currentStep + 1)
        } else {
            self._comparedStep = State(initialValue: 0)
        }
    }

    var body: some View {
        let dynamicLayout = layoutHorizontal ? AnyLayout(HStackLayout(alignment: .top, spacing: 24)) : AnyLayout(VStackLayout(spacing: 24))

        ScrollView {
            dynamicLayout {
                circuitPanel(step: $currentStep, circuit: currentCircuit, parseError: parseErrorCurrentCircuit)
                circuitPanel(step: $comparedStep, circuit: comparedCircuit, parseError: parseErrorComparedCircuit)
            }
            .padding()
        }
        .background(Color.grayBackground.ignoresSafeArea())
        // Centralized Keyboard Shortcuts (affect compared ciruit or both if isLinked is set)
        .background {
            Button("") { stepBackward() }.keyboardShortcut(.leftArrow, modifiers: [])
            Button("") { stepForward() }.keyboardShortcut(.rightArrow, modifiers: [])
        }
        .navigationTitle("Compare Evolution")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Toggle(isOn: $isLinked) {
                    Image(systemName: "link")
                        .foregroundColor(isLinked ? .white : .primary)
                }
                .help("Link Circuit Steppers")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        layoutHorizontal.toggle()
                    }
                }) {
                    Image(systemName: layoutHorizontal ? "rectangle.split.1x2" : "rectangle.split.2x1")
                }
                .help(layoutHorizontal ? "Switch to Vertical Layout" : "Switch to Horizontal Layout")
            }
        }
        .onAppear(perform: loadCircuits)
        .onChange(of: currentStep) { oldStep, newStep in
            loadCurrentCircuit()
            syncSteps(fromPrimary: true, oldVal: oldStep, newVal: newStep)
        }
        .onChange(of: comparedStep) { oldStep, newStep in
            loadComparedCircuit()
            syncSteps(fromPrimary: false, oldVal: oldStep, newVal: newStep)
        }
        .hideKeyboardOnTap()
    }

    // MARK: - Subcomponents

    @ViewBuilder
    private func circuitPanel(step: Binding<Int>, circuit: ParsedCircuit?, parseError: String?) -> some View {
        let isValid = step.wrappedValue >= 0 && step.wrappedValue < trace.steps.count
        let actionName = isValid ? trace.steps[step.wrappedValue].action : "Unknown Action"

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isValid, let parsed = circuit {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            let currentStep = trace.steps[step.wrappedValue]

                            Label("\(parsed.operations.count) Ops", systemImage: "cpu")
                            Label("\(currentStep.numQubits) Qubits", systemImage: "circle.dotted.and.circle")
                            Label(String(format: "Depth %.2f", currentStep.rawCriticalDepth), systemImage: "arrow.down.to.line.compact")
                            Label(String(format: "Parallelism %.2f", currentStep.parallelism), systemImage: "bolt")
                            Label(String(format: "Liveness %.2f", currentStep.liveness), systemImage: "waveform.path.ecg")
                            Label(String(format: "Entanglement %.2f", currentStep.entanglementRatio), systemImage: "point.3.connected.trianglepath.dotted")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                    }
                } else {
                    Text("Calculating...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                ActionStepperView(
                    totalSteps: trace.steps.count,
                    enableKeyboardShortcuts: false,
                    currentStep: step
                )
            }

            DashboardCardView(title: actionName) {
                VStack(alignment: .center, spacing: 16) {
                    if let circuit = circuit {
                        CanvasRenderView(
                            currentCircuit: circuit,
                            rowHeight: rowHeight,
                            defaultColumnWidth: minColumnWidth
                        )
                    } else if let error = parseError {
                        ParsingErrorView(error: error)
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.small)
                                .progressViewStyle(.circular)
                                .foregroundStyle(.gray)
                                .tint(.gray)
                            Text("Parsing circuit...")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                    }
                }
            }
        }
    }

    // MARK: - Logic

    private func stepBackward() {
        if comparedStep > 0 {
            withAnimation(.easeInOut(duration: 0.2)) {
                comparedStep -= 1
            }
        }
    }

    private func stepForward() {
        if comparedStep < trace.steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                comparedStep += 1
            }
        }
    }

    /// Synchronizes the timelines when the link toggle is active.
    private func syncSteps(fromPrimary: Bool, oldVal: Int, newVal: Int) {
        // Prevent infinite loops caused by onChange ping-ponging
        guard isLinked, !isSyncing else { return }
        isSyncing = true

        let delta = newVal - oldVal

        withAnimation(.easeInOut(duration: 0.2)) {
            if fromPrimary {
                comparedStep = min(max(comparedStep + delta, 0), trace.steps.count - 1)
            } else {
                currentStep = min(max(currentStep + delta, 0), trace.steps.count - 1)
            }
        }

        // Reset the syncing flag on the next run loop after states have settled
        DispatchQueue.main.async {
            isSyncing = false
        }
    }

    private func loadCircuits() {
        loadCurrentCircuit()
        loadComparedCircuit()
    }

    private func loadCurrentCircuit() {
        guard currentStep >= 0 && currentStep < trace.steps.count else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            do {
                parseErrorCurrentCircuit = nil
                currentCircuit = try QASMParser.parse(qasm: trace.steps[currentStep].circuitQasm3)
            } catch {
                currentCircuit = nil
                parseErrorCurrentCircuit = error.localizedDescription
            }
        }
    }

    private func loadComparedCircuit() {
        guard comparedStep >= 0 && comparedStep < trace.steps.count else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            do {
                parseErrorComparedCircuit = nil
                comparedCircuit = try QASMParser.parse(qasm: trace.steps[comparedStep].circuitQasm3)
            } catch {
                comparedCircuit = nil
                parseErrorComparedCircuit = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        EvolutionComparisonView(trace: CompilationTrace.previewMock, currentStep: 0)
    }
}
