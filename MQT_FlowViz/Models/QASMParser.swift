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
    
    /// Represents possible QASM parsing errors.
    enum QASMParseError: LocalizedError {
        case unsupportedVersion(String)
        case missingQubits(line: Int, instruction: String)
        case unknownInstruction(line: Int, instruction: String)

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let version):
                return "Unsupported QASM version: '\(version)'. MQT FlowViz strictly requires OPENQASM 3.0."
            case .missingQubits(let line, let instruction):
                return "Syntax Error on line \(line): Expected target qubits for operation '\(instruction)'."
            case .unknownInstruction(let line, let instruction):
                return "Parse Error on line \(line): Unrecognized instruction '\(instruction)'."
            }
        }
    }
    
    /// Attempts to parse a given string that follows QASM 3.0 format.
    /// - Parameter qasm: A QASM 3.0 string.
    /// - Returns: An instance of ``ParsedCircuit`` upon success.
    static func parse(qasm: String) throws -> ParsedCircuit {
        var operations: [CircuitOperation] = []
        var currentMomentPerWire: [Int: Int] = [:]

        let lines = qasm.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        var isInsideGateDefinition = false

        // MARK: - General Parsing
        for (index, line) in lines.enumerated() {
            // used for error messages
            let lineNumber = index + 1

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

            if line.hasPrefix("OPENQASM") {
                guard line.contains("3.0") else {
                    throw QASMParseError.unsupportedVersion(line)
                }
                continue
            }

            // 2) Skip comments, headers, and Qubit Declarations!
            guard !line.isEmpty, !line.hasPrefix("//"), !line.hasPrefix("OPENQASM"),
                  !line.hasPrefix("include"), !line.hasPrefix("qubit["), !line.hasPrefix("qreg "),
                  !line.hasPrefix("bit["), !line.hasPrefix("creg "),
                  !line.hasPrefix("global_phase")
            else { continue }

            // 3) Handle Measurement Operations
            if line.contains("measure") {
                if let qMatch = match(pattern: "(?:q\\[|\\$)(\\d+)(?:\\])?", in: line),
                   let cMatch = match(pattern: "(?:c|meas)\\[(\\d+)\\]", in: line),
                   let qBit = Int(qMatch), let cBit = Int(cMatch) {

                    let moment = currentMomentPerWire[qBit] ?? 0
                    operations.append(CircuitOperation(type: .measurement(qubit: qBit, classicalBit: cBit), momentIndex: moment))
                    currentMomentPerWire[qBit] = moment + 1
                    continue
                }
                logger.error("[MEASURE] - Could not parse suspected measurement instruction: \(line)")
                throw QASMParseError.unknownInstruction(line: lineNumber, instruction: line)
            }

            // 4) Handle Barrier Operations
            if line.hasPrefix("barrier") {
                let qubits = extractAllQubitIntegers(from: line)
                if !qubits.isEmpty {
                    let maxMoment = qubits.compactMap { currentMomentPerWire[$0] }.max() ?? 0
                    operations.append(CircuitOperation(type: .barrier(qubits: qubits), momentIndex: maxMoment))
                    // Push all involved wires to the same timeline position
                    for q in qubits { currentMomentPerWire[q] = maxMoment + 1 }
                } else {
                    // No qubits specified implies global barrier across all active qubits
                    let allKnownQubits = Array(currentMomentPerWire.keys)
                    if !allKnownQubits.isEmpty {
                        let maxMoment = allKnownQubits.compactMap { currentMomentPerWire[$0] }.max() ?? 0
                        operations.append(CircuitOperation(type: .barrier(qubits: allKnownQubits), momentIndex: maxMoment))
                        for q in allKnownQubits { currentMomentPerWire[q] = maxMoment + 1 }
                    }
                }
                continue
            }

            // 5) Handle Logic Gates
            let cleanLine = line.replacingOccurrences(of: ";", with: "")

            // Find the first occurrence of either "q[" or "$"
            let qIndex = cleanLine.range(of: "q[")?.lowerBound
            let dollarIndex = cleanLine.range(of: "$")?.lowerBound
            let gateIdentifierEndIndex = [qIndex, dollarIndex].compactMap { $0 }.min() ?? cleanLine.endIndex

            let rawGateIdentifier = String(cleanLine[..<gateIdentifierEndIndex]).trimmingCharacters(in: .whitespaces)

            guard !rawGateIdentifier.isEmpty else {
                logger.error("Could not extract raw gate identifier for line: \(line)")
                throw QASMParseError.unknownInstruction(line: lineNumber, instruction: line)
            }

            let involvedQubits = extractAllQubitIntegers(from: cleanLine)
            guard !involvedQubits.isEmpty else {
                logger.error("[GATE] - No qubits found in gate: \(rawGateIdentifier), in line: \(line)")
                throw QASMParseError.missingQubits(line: lineNumber, instruction: rawGateIdentifier)
            }

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

            // --- EXTRACT BASE GATE & MODIFIERS ---
            var baseGateIdentifier = rawGateIdentifier
            var isInverse = false
            var power: String? = nil

            // 1. Check for the inverse modifier
            if let invRange = baseGateIdentifier.range(of: "(?i)inv\\s*@\\s*", options: .regularExpression) {
                isInverse = true
                baseGateIdentifier.removeSubrange(invRange)
            }

            // 2. Check for the power modifier
            if let powRange = baseGateIdentifier.range(of: "(?i)pow\\(([^)]+)\\)\\s*@\\s*", options: .regularExpression) {
                // Extract the value inside the parentheses
                let matchString = String(baseGateIdentifier[powRange])
                if let paramStart = matchString.firstIndex(of: "("), let paramEnd = matchString.firstIndex(of: ")") {
                    let start = matchString.index(after: paramStart)
                    power = String(matchString[start..<paramEnd])
                }
                baseGateIdentifier.removeSubrange(powRange)
            }

            // 3. Check for the ctrl modifier
            while let ctrlRange = baseGateIdentifier.range(of: "(?i)ctrl(?:\\(\\d+\\))?\\s*@\\s*", options: .regularExpression) {
                baseGateIdentifier.removeSubrange(ctrlRange)
            }

            // --- EXTRACT GATE PARAMETERS ---
            // Now that modifiers are stripped out, check if the remaining base gate has parameters (e.g., "rx(pi/2)")
            var parameter: String? = nil
            if let paramStart = baseGateIdentifier.firstIndex(of: "("), let paramEnd = baseGateIdentifier.lastIndex(of: ")") {
                let start = baseGateIdentifier.index(after: paramStart)
                let rawParameter = String(baseGateIdentifier[start..<paramEnd])
                parameter = formatParameter(rawParameter)
            }

            // --- FORMAT THE UI LABEL ---
            var gateName = baseGateIdentifier.components(separatedBy: "(").first ?? baseGateIdentifier

            // Append modifiers to the visual label
            if let power = power {
                gateName += "^\(power)" // e.g., x^0.5
            }
            if isInverse {
                gateName += "†" // e.g., s†
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
            // Regex matches either "q[<digits>]" OR "$<digits>"
            let regex = try NSRegularExpression(pattern: "(?:q\\[|\\$)(\\d+)(?:\\])?")
            let nsString = string as NSString
            let results = regex.matches(in: string, range: NSRange(location: 0, length: nsString.length))
            return results.compactMap { Int(nsString.substring(with: $0.range(at: 1))) }
        } catch {
            return []
        }
    }

    /// Searches a parameter string for numbers and neatly formats them. Replaces "pi" with "π" and cleans up multiplication syntax.
    ///
    /// Leaves non-numeric characters (like 'pi') untouched.
    /// - Parameter parameter: The label of a quantum gate.
    /// - Returns: The formatted label.
    private static func formatParameter(_ gateLabel: String) -> String {
        do {
            // Regex matches floats, including optional scientific notation (e.g., -0.123, 1.5e-4)
            let regex = try NSRegularExpression(pattern: "[-+]?\\d*\\.\\d+(?:[eE][-+]?\\d+)?")
            let nsString = gateLabel as NSString
            let results = regex.matches(in: gateLabel, range: NSRange(location: 0, length: nsString.length))

            var formattedString = gateLabel

            // Use NumberFormatter for clean, trailing-zero-free formatting
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 3
            formatter.minimumFractionDigits = 0
            formatter.decimalSeparator = "."

            // Iterate in reverse so modifying the string doesn't shift the index ranges
            for result in results.reversed() {
                let matchString = nsString.substring(with: result.range)
                if let value = Double(matchString),
                   let formattedValue = formatter.string(from: NSNumber(value: value)) {
                    formattedString = (formattedString as NSString).replacingCharacters(in: result.range, with: formattedValue)
                }
            }

            // 1. Replace "pi" with "π"
            // 2. Remove asterisks attached to π (e.g., "3*π/2" -> "3π/2")
            return formattedString
                .replacingOccurrences(of: "pi", with: "π", options: .caseInsensitive)
                .replacingOccurrences(of: "*π", with: "π")
                .replacingOccurrences(of: "π*", with: "π")

        } catch {
            return gateLabel.replacingOccurrences(of: "pi", with: "π", options: .caseInsensitive)
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
