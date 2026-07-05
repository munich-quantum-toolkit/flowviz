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
        enum WireID: Hashable { case q(Int), c(Int) }

        var currentMomentPerWire: [WireID: Int] = [:]

        // Track qubits that are explicitly defined in the instructions (relevant for barrier and possible other global instructions)
        var explicitlyActiveQubits: Set<Int> = []
        var usedClassicalControls: Set<Int> = []

        // Tracks if we are currently inside an 'if' block
        var currentlyActiveIfControlBits: [Int] = []

        var operations: [CircuitOperation] = []

        let lines = qasm.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        var isInsideGateDefinition = false

        // Pre-scan the entire file to find which classical bits are actually used in 'if' blocks,
        // enabling us to prevent unnecessary space allocation for measurement operations.
        for line in lines {
            if line.hasPrefix("if") {
                let cBits = extractAllClassicalBitIntegers(from: line)
                for bit in cBits {
                    usedClassicalControls.insert(bit)
                }
            }
        }

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

            // 2) Skip comments, headers, and Global Phase
            guard !line.isEmpty, !line.hasPrefix("//"), !line.hasPrefix("OPENQASM"),
                  !line.hasPrefix("include"), !line.hasPrefix("global_phase")
            else { continue }

            // 2.5) Handle Declarations early to map the full circuit canvas
            if line.hasPrefix("qubit[") || line.hasPrefix("qreg ") {
                if let count = extractFirstInteger(from: line) {
                    for i in 0..<count { explicitlyActiveQubits.insert(i) }
                }
                continue
            }
            if line.hasPrefix("bit[") || line.hasPrefix("creg ") {
                // We don't need to track raw bit declarations.
                // The pre-scan above handles the ones we actually care about.
                continue
            }

            // 3) Handle Measurement Operations
            if line.contains("measure") {
                if let qMatch = match(pattern: "(?:q\\[|\\$)(\\d+)(?:\\])?", in: line),
                   let cMatch = match(pattern: "(?:c|meas)\\[(\\d+)\\]", in: line),
                   let qBit = Int(qMatch), let cBit = Int(cMatch) {
                    explicitlyActiveQubits.insert(qBit)

                    let crossedWires: [WireID]

                    // Check if the UI will actually draw a line down for this measurement
                    if usedClassicalControls.contains(cBit) {
                        let crossedQ = explicitlyActiveQubits.filter { $0 >= qBit }.map { WireID.q($0) }
                        let crossedC = usedClassicalControls.filter { $0 <= cBit }.map { WireID.c($0) }
                        crossedWires = crossedQ + crossedC
                    } else {
                        // If no classical wire is drawn, this measurement only occupies its own qubit wire
                        crossedWires = [.q(qBit)]
                    }

                    let moment = crossedWires.compactMap { currentMomentPerWire[$0] }.max() ?? 0

                    operations.append(CircuitOperation(type: .measurement(qubit: qBit, classicalBit: cBit), momentIndex: moment))

                    for wire in crossedWires { currentMomentPerWire[wire] = moment + 1 }
                    continue
                }
                logger.error("[MEASURE] - Could not parse suspected measurement instruction: \(line)")
                throw QASMParseError.unknownInstruction(line: lineNumber, instruction: line)
            }

            // 3.5) Handle If Blocks
            if line.hasPrefix("if") {
                let cBits = extractAllClassicalBitIntegers(from: line)
                if !cBits.isEmpty {
                    currentlyActiveIfControlBits = cBits
                }
                continue
            }

            // Exit the if block when closing brace is hit
            if !currentlyActiveIfControlBits.isEmpty && line.contains("}") {
                currentlyActiveIfControlBits = [] // Clear the array for next line
                continue
            }

            // 4) Handle Barrier Operations
            if line.hasPrefix("barrier") {
                let qubits = extractAllQubitIntegers(from: line)
                let barrierQubits: [Int]

                if !qubits.isEmpty {
                    barrierQubits = qubits
                } else {
                    // Global barrier: Use only explicitly active qubits
                    barrierQubits = Array(explicitlyActiveQubits).sorted()
                }

                if !barrierQubits.isEmpty {
                    explicitlyActiveQubits.formUnion(barrierQubits)

                    // Safely reserve the full vertical span of the barrier so gates don't overlap it
                    let minQ = barrierQubits.min() ?? 0
                    let maxQ = barrierQubits.max() ?? 0

                    // Standard barriers only span quantum wires
                    let crossedWires = (minQ...maxQ).map { WireID.q($0) }
                    let maxMoment = crossedWires.compactMap { currentMomentPerWire[$0] }.max() ?? 0

                    operations.append(CircuitOperation(type: .barrier(qubits: barrierQubits), momentIndex: maxMoment))

                    for wire in crossedWires { currentMomentPerWire[wire] = maxMoment + 1 }
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

            explicitlyActiveQubits.formUnion(involvedQubits) // Track explicitly used qubits

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

            // 1. Check for & remove the inverse modifier
            if let invRange = baseGateIdentifier.range(of: "(?i)inv\\s*@\\s*", options: .regularExpression) {
                isInverse = true
                baseGateIdentifier.removeSubrange(invRange)
            }

            // 2. Check for $ remove the power modifier
            if let powRange = baseGateIdentifier.range(of: "(?i)pow\\(([^)]+)\\)\\s*@\\s*", options: .regularExpression) {
                // Extract the value inside the parentheses
                let matchString = String(baseGateIdentifier[powRange])
                if let paramStart = matchString.firstIndex(of: "("), let paramEnd = matchString.firstIndex(of: ")") {
                    let start = matchString.index(after: paramStart)
                    power = String(matchString[start..<paramEnd])
                }
                baseGateIdentifier.removeSubrange(powRange)
            }

            // 3. Remove the ctrl modifier
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

            if let power = power { gateName += "^\(power)" }
            if isInverse { gateName += "†" }

            // --- APPEND OPERATION & RESERVE SPAN ---

            let minQubit = involvedQubits.min() ?? 0
            let maxQubit = involvedQubits.max() ?? 0
            var crossedWires: [WireID] = []

            if !currentlyActiveIfControlBits.isEmpty {
                // Find the lowest physical classical bit (highest index) so we span the whole distance
                let maxCBit = currentlyActiveIfControlBits.max() ?? 0

                let crossedQ = explicitlyActiveQubits.filter { $0 >= minQubit }.map { WireID.q($0) }
                let crossedC = usedClassicalControls.filter { $0 <= maxCBit }.map { WireID.c($0) }
                crossedWires = crossedQ + crossedC
            } else {
                // Standard quantum gate spans between its top and bottom explicitly involved qubits
                crossedWires = (minQubit...maxQubit).map { WireID.q($0) }
            }

            let finalMoment = crossedWires.compactMap { currentMomentPerWire[$0] }.max() ?? 0

            // The array is passed directly in instead of the single wrapped bit
            if controls.isEmpty && targets.count == 1 {
                operations.append(CircuitOperation(type: .singleQubit(target: targets[0], label: gateName, parameter: parameter), momentIndex: finalMoment, classicalControls: currentlyActiveIfControlBits))
            } else if controls.count == 1 && targets.count == 1 {
                operations.append(CircuitOperation(type: .multiQubit(control: controls[0], target: targets[0], label: gateName, parameter: parameter), momentIndex: finalMoment, classicalControls: currentlyActiveIfControlBits))
            } else {
                operations.append(CircuitOperation(type: .nQubit(controls: controls, targets: targets, label: gateName), momentIndex: finalMoment, classicalControls: currentlyActiveIfControlBits))
            }

            // Advance the moment for every wire that is physically crossed to prevent overlaps
            for wire in crossedWires {
                currentMomentPerWire[wire] = finalMoment + 1
            }
        }

        logger.info("Finished raw parsing of string \(qasm)\nProceeding to compaction.")

        // MARK: - Compaction Phase

        // 1. Sort the explicitly tracked qubits and classical bits so they appear in standard ascending order
        let sortedQubits = Array(explicitlyActiveQubits).sorted()
        let sortedCBits = Array(usedClassicalControls).sorted()

        // 2. Create mappings from physical hardware indices to visual UI row indices
        var physicalToVisualMapQ: [Int: Int] = [:]
        var physicalToVisualMapC: [Int: Int] = [:]
        var compactedWires: [Wire] = []

        // Add Quantum Wires (These go at the top)
        for (visualIndex, physicalId) in sortedQubits.enumerated() {
            physicalToVisualMapQ[physicalId] = visualIndex
            compactedWires.append(Wire(id: visualIndex, label: "q[\(physicalId)]", isClassical: false))
        }

        // Add Classical Wires (These go at the bottom, continuing the visual index count)
        let qCount = sortedQubits.count
        for (index, physicalId) in sortedCBits.enumerated() {
            let visualIndex = qCount + index
            physicalToVisualMapC[physicalId] = visualIndex
            compactedWires.append(Wire(id: visualIndex, label: "c[\(physicalId)]", isClassical: true))
        }

        // 3. Adjust applied operations to use the new visual row indices
        let compactedOperations = operations.map { op -> CircuitOperation in

            // A. Map physical classical controls (from 'if' blocks) to visual indices
            let mappedClassicalControls = op.classicalControls.compactMap { physicalToVisualMapC[$0] }

            // B. Map GateVisualType hardware targets to visual rows
            let mappedType: GateVisualType
            switch op.type {
            case .singleQubit(let target, let label, let param):
                mappedType = .singleQubit(target: physicalToVisualMapQ[target]!, label: label, parameter: param)

            case .multiQubit(let control, let target, let label, let param):
                mappedType = .multiQubit(control: physicalToVisualMapQ[control]!, target: physicalToVisualMapQ[target]!, label: label, parameter: param)

            case .nQubit(let controls, let targets, let label):
                let mappedControls = controls.compactMap { physicalToVisualMapQ[$0] }
                let mappedTargets = targets.compactMap { physicalToVisualMapQ[$0] }
                mappedType = .nQubit(controls: mappedControls, targets: mappedTargets, label: label)

            case .barrier(let qubits):
                mappedType = .barrier(qubits: qubits.compactMap { physicalToVisualMapQ[$0] })

            case .measurement(let qubit, let classicalBit):
                // Measurements bridge the gap: quantum source, classical destination
                let visualCBit = classicalBit.flatMap { physicalToVisualMapC[$0] }
                mappedType = .measurement(qubit: physicalToVisualMapQ[qubit]!, classicalBit: visualCBit)
            }

            // Return a fresh operation with the updated visual mappings
            return CircuitOperation(
                type: mappedType,
                momentIndex: op.momentIndex,
                classicalControls: mappedClassicalControls
            )
        }

        logger.info("Compaction phase finished successfully.")

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

    /// Extracts all integers corresponding to a classical bit declaration in a QASM line.
    /// - Parameter string: The string to be searched.
    /// - Returns: An array of all occuring integer values associated with a classical bit.
    private static func extractAllClassicalBitIntegers(from string: String) -> [Int] {
        do {
            let regex = try NSRegularExpression(pattern: "(?:c|meas)\\[(\\d+)\\]")
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
