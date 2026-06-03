//
//  QASMParser.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 22.05.26.
//

import Foundation
import OSLog

final class QASMParser {
    static let logger: Logger = Logger(subsystem: "QASMParsing", category: "QASMParser")

    /* Sample QASM String for reference:
     OPENQASM 3.0;\ninclude \"stdgates.inc\";\nbit[3] meas;\nqubit[127] q;\nrz(-3*pi/2) q[98];\nsx q[98];\nrz(-pi/2) q[98];\nrz(-pi/2) q[99];\nsx q[99];\nrz(4.578679574453913) q[99];\nsx q[99];\nrz(5*pi/2) q[99];\ncx q[98], q[99];\nrz(-pi/2) q[99];\nsx q[99];\nrz(4.578679574453913) q[99];\nsx q[99];\nrz(5*pi/2) q[99];\ncx q[99], q[100];\nmeas[0] = measure q[69];\nmeas[1] = measure q[67];\nmeas[2] = measure q[120];\n

     OPENQASM 3.0;\ninclude \"stdgates.inc\";\nbit[3] meas;\nqubit[3] q;\nh q[2];\ncx q[2], q[1];\ncx q[1], q[0];\nbarrier q[0], q[1], q[2];\nmeas[0] = measure q[0];\nmeas[1] = measure q[1];\nmeas[2] = measure q[2];\n

     OPENQASM 2.0;\ninclude \"qelib1.inc\";\ngate gate_Oracle q0,q1,q2 { x q0; x q1; cx q0,q2; cx q1,q2; x q0; x q1; }\nqreg q[3];\ncreg c[2];\nx q[2];\nh q[2];\nh q[0];\nh q[1];\ngate_Oracle q[0],q[1],q[2];\nh q[0];\nh q[1];\nbarrier q[0],q[1],q[2];\nmeasure q[0] -> c[0];\nmeasure q[1] -> c[1];

     */

    static func parse(qasm: String) -> ParsedCircuit {
        var operations: [CircuitOperation] = []
        var currentMomentPerWire: [Int: Int] = [:]

        let lines = qasm.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        var isInsideGateDefinition = false

        // MARK: - General Parsing
        for line in lines {
            // 1) Skip custom gate definition blocks
            if line.hasPrefix("gate ") && line.contains("{") && line.contains("}") { continue }
            if line.hasPrefix("gate ") && line.contains("{") && !line.contains("}") {
                isInsideGateDefinition = true
                continue
            }
            if isInsideGateDefinition && line.contains("}") {
                isInsideGateDefinition = false
                continue
            }
            if isInsideGateDefinition { continue }

            // 2) Skip comments, headers, and Qubit Declarations!
            guard !line.isEmpty, !line.hasPrefix("//"), !line.hasPrefix("OPENQASM"), !line.hasPrefix("include"), !line.hasPrefix("qubit["), !line.hasPrefix("qreg ") else { continue }

            // 3) Handle Measurement Operations
            if line.contains("measure") {
                if let qMatch = match(pattern: "q\\[(\\d+)\\]", in: line),
                   let cMatch = match(pattern: "(?:c|meas)\\[(\\d+)\\]", in: line),
                   let qBit = Int(qMatch), let cBit = Int(cMatch) {

                    let moment = currentMomentPerWire[qBit] ?? 0
                    operations.append(CircuitOperation(type: .measurement(qubit: qBit, classicalBit: cBit), momentIndex: moment))
                    currentMomentPerWire[qBit] = moment + 1
                    continue
                }
                logger.warning("[MEASURE] - Could not parse suspected measurement instruction: \(line)")
                continue
            }

            // 4) Handle Barrier Operations
            if line.hasPrefix("barrier") {
                let qubits = extractAllQubitIntegers(from: line)
                if !qubits.isEmpty {
                    let maxMoment = qubits.compactMap { currentMomentPerWire[$0] }.max() ?? 0
                    operations.append(CircuitOperation(type: .barrier(qubits: qubits), momentIndex: maxMoment))

                    // Push all involved wires to the same timeline position
                    for q in qubits { currentMomentPerWire[q] = maxMoment + 1 }
                }
                continue
            }

            // 5) Handle Logic Gates
            let cleanLine = line.replacingOccurrences(of: ";", with: "")

            // Extract everything before the first qubit declaration as the gate identifier
            // For instance "ctrl @ x q[0]" splits into ""ctrl @ x " and "q[0]"
            let gateIdentifierEndIndex = cleanLine.range(of: "q[")?.lowerBound ?? cleanLine.endIndex
            let rawGateIdentifier = String(cleanLine[..<gateIdentifierEndIndex]).trimmingCharacters(in: .whitespaces)

            guard !rawGateIdentifier.isEmpty else {
                logger.warning("Could not extract raw gate identifier for line: \(line)")
                continue
            }

            let involvedQubits = extractAllQubitIntegers(from: cleanLine)
            guard !involvedQubits.isEmpty else { continue }

            // --- OBTAIN CONTROL/TARGET QUBITS ---
            var numControls = 0
            let lowerGate = rawGateIdentifier.lowercased()
            let baseGateName = lowerGate.components(separatedBy: "(").first ?? lowerGate

            // 1. Check for explicit QASM 3 modifiers (e.g., "ctrl @ ctrl @" or "ctrl(5)")
            if lowerGate.contains("ctrl") {
                if let match = match(pattern: "ctrl\\((\\d+)\\)", in: lowerGate), let k = Int(match) {
                    numControls = k
                } else {
                    numControls = lowerGate.components(separatedBy: "ctrl").count - 1
                }
            }
            // 2. Check for matches of standard 3-qubit gates included in the QASM standard library
            else if baseGateName == "ccx" {
                numControls = 2
            } else if baseGateName == "cswap" || baseGateName == "cswp" {
                numControls = 1
            }
            // 3. Check for standard 2-qubit controlled gates in the QASM standard library
            else if involvedQubits.count == 2 {
                let standardControlledGates = ["cx", "cy", "cz", "ch", "cp", "crx", "cry", "crz", "cu"]
                if standardControlledGates.contains(baseGateName) {
                    numControls = 1
                }
            }

            // Safety clamp (in case there would be a faulty QASM string that has more ctrls than qubits, for instance)
            numControls = min(numControls, involvedQubits.count - 1)

            let controls = Array(involvedQubits.prefix(numControls))
            let targets = Array(involvedQubits.dropFirst(numControls))

            // --- EXTRACT BASE GATE ---
            // Strip out possible "ctrl @" prefixes to find the clean base gate for the UI label
            var baseGateIdentifier = rawGateIdentifier
            while let range = baseGateIdentifier.range(of: "(?i)ctrl(?:\\(\\d+\\))?\\s*@\\s*", options: .regularExpression) {
                baseGateIdentifier.removeSubrange(range)
            }

            let gateName = baseGateIdentifier.components(separatedBy: "(").first ?? baseGateIdentifier
            var parameter: String? = nil

            if let paramStart = baseGateIdentifier.firstIndex(of: "("), let paramEnd = baseGateIdentifier.lastIndex(of: ")") {
                let start = baseGateIdentifier.index(after: paramStart)
                let rawParameter = String(baseGateIdentifier[start..<paramEnd])
                parameter = formatParameter(rawParameter)
            }

            // --- APPEND OPERATION & RESERVE SPAN ---

            // 1. Calculate the full vertical span of this gate
            let minQubit = involvedQubits.min() ?? 0
            let maxQubit = involvedQubits.max() ?? 0
            let spannedQubits = Array(minQubit...maxQubit)

            // 2. Find the latest available moment across the entire span
            let moment = spannedQubits.compactMap { currentMomentPerWire[$0] }.max() ?? 0

            // 3. Append the operation (only the explicitly involved qubits are passed to the UI)
            if controls.isEmpty && targets.count == 1 {
                operations.append(CircuitOperation(type: .singleQubit(target: targets[0], label: gateName, parameter: parameter), momentIndex: moment))
            } else if controls.count == 1 && targets.count == 1 {
                operations.append(CircuitOperation(type: .multiQubit(control: controls[0], target: targets[0], label: gateName), momentIndex: moment))
            } else {
                operations.append(CircuitOperation(type: .nQubit(controls: controls, targets: targets, label: gateName), momentIndex: moment))
            }

            // 4. Advance the moment for every wire in the span to prevent overlaps
            for q in spannedQubits {
                currentMomentPerWire[q] = moment + 1
            }
        }

        logger.info("Finished raw parsing of string \(qasm). Proceeding to compaction.")

        // MARK: - Compaction Phase

        // 1. Find all physical qubits that actually have operations
        var activePhysicalQubits: Set<Int> = []
        for op in operations {
            activePhysicalQubits.formUnion(op.involvedQubits)
        }

        // 2. Sort qubits so the wires appear in standard ascending order (e.g. 67, 69, 98...)
        let sortedQubits = Array(activePhysicalQubits).sorted()

        // 3. Create a mapping from physical qubit index to a visual row index
        var physicalToVisualMap: [Int: Int] = [:]
        var compactedWires: [Wire] = []

        for (visualIndex, physicalId) in sortedQubits.enumerated() {
            physicalToVisualMap[physicalId] = visualIndex
            // Wire keeps hardware label but gets a visual index for Canvas drawing logic
            compactedWires.append(Wire(id: visualIndex, label: "q[\(physicalId)]"))
        }

        // 4. Adjust applied operations to use the visual indices
        let compactedOperations = operations.map { op -> CircuitOperation in
            let mappedType: GateVisualType

            switch op.type {
            case .singleQubit(let target, let label, let param):
                mappedType = .singleQubit(target: physicalToVisualMap[target]!, label: label, parameter: param)

            case .multiQubit(let control, let target, let label):
                mappedType = .multiQubit(control: physicalToVisualMap[control]!, target: physicalToVisualMap[target]!, label: label)

            case .nQubit(let controls, let targets, let label):
                let mappedControls = controls.compactMap { physicalToVisualMap[$0] }
                let mappedTargets = targets.compactMap { physicalToVisualMap[$0] }
                mappedType = .nQubit(controls: mappedControls, targets: mappedTargets, label: label)

            case .barrier(let qubits):
                mappedType = .barrier(qubits: qubits.compactMap { physicalToVisualMap[$0] })

            case .measurement(let qubit, let classicalBit):
                mappedType = .measurement(qubit: physicalToVisualMap[qubit]!, classicalBit: classicalBit)
            }

            return CircuitOperation(type: mappedType, momentIndex: op.momentIndex)
        }

        logger.info("Compaction phase finished successfully: \(physicalToVisualMap).")

        return ParsedCircuit(wires: compactedWires, operations: compactedOperations)
    }

    // MARK: - Helpers
    
    /// Extracts the first occuring integer value from a string.
    /// - Parameter string: The string to be searched.
    /// - Returns: The first occuring integer.
    private static func extractFirstInteger(from string: String) -> Int? {
        guard let match = match(pattern: "\\[(\\d+)\\]", in: string) else { return nil }
        return Int(match)
    }
    
    /// Extracts all integers corresponding to a Qubit declaration in a QASM line..
    /// - Parameter string: The string to be searched.
    /// - Returns: An array of all occuring integer values associated with a qubit.
    private static func extractAllQubitIntegers(from string: String) -> [Int] {
        do {
            let regex = try NSRegularExpression(pattern: "q\\[(\\d+)\\]")
            let nsString = string as NSString
            let results = regex.matches(in: string, range: NSRange(location: 0, length: nsString.length))
            return results.compactMap { Int(nsString.substring(with: $0.range(at: 1))) }
        } catch {
            return []
        }
    }

    /// Searches a parameter string for floating-point numbers and formats them to 3 decimal places. Additionally replaces "pi" with "π".
    ///
    /// Leaves non-numeric characters (like 'pi') untouched.
    /// - Parameter parameter: The label of a quantum gate.
    /// - Returns: The formatted label.
    private static func formatParameter(_ gateLabel: String) -> String {
        do {
            // Matches optional +/- followed by optional digits, a dot, and 1 or more digits (e.g., -4.578679)
            let regex = try NSRegularExpression(pattern: "[-+]?\\d*\\.\\d+")
            let nsString = gateLabel as NSString
            let results = regex.matches(in: gateLabel, range: NSRange(location: 0, length: nsString.length))

            var formattedString = gateLabel

            // Iterate in reverse so modifying the string doesn't shift the index ranges of earlier matches
            for result in results.reversed() {
                let matchString = nsString.substring(with: result.range)
                if let value = Double(matchString) {
                    let formattedValue = String(format: "%.3f", value)
                    formattedString = (formattedString as NSString).replacingCharacters(in: result.range, with: formattedValue)
                }
            }
            return formattedString.replacingOccurrences(
                of: "pi",
                with: "π",
                options: .caseInsensitive
            )
        } catch {
            return gateLabel.replacingOccurrences(
                of: "pi",
                with: "π",
                options: .caseInsensitive
            )
        }
    }

    /// Matches a given regex pattern against a provided string.
    /// - Parameters:
    ///   - pattern: The regex pattern to check for.
    ///   - string: The string to be checked.
    /// - Returns: The first substring matching the pattern or nil, if the string does not contain the pattern.
    private static func match(pattern: String, in string: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = string as NSString
            if let result = regex.firstMatch(in: string, range: NSRange(location: 0, length: nsString.length)) {
                if result.numberOfRanges > 1 {
                    return nsString.substring(with: result.range(at: 1))
                }
            }
            return nil
        } catch {
            return nil
        }
    }
}
