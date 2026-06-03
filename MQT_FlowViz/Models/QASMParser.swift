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
                let qubits = extractAllIntegers(from: line)
                if !qubits.isEmpty {
                    let maxMoment = qubits.compactMap { currentMomentPerWire[$0] }.max() ?? 0
                    operations.append(CircuitOperation(type: .barrier(qubits: qubits), momentIndex: maxMoment))

                    // Push all involved wires to the same timeline position
                    for q in qubits { currentMomentPerWire[q] = maxMoment + 1 }
                }
                continue
            }

            // 5) Handle Logic Gates (e.g. `cx q[0], q[1];` or `rz(-pi/2) q[4];`)
            // Split the gate identifier from the affected qubit(s)
            let cleanLine = line.replacingOccurrences(of: ";", with: "")
            let parts = cleanLine.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else {
                logger.warning("[LOGIC GATES] - Could not parse suspected logic gate: \(line)")
                continue
            }

            let gateIdentifier = String(parts[0])
            let qubitsPart = String(parts[1])

            // Separate the gate name from its parameter, if it has one (e.g., U(pi/2, 0, pi))
            let gateName = gateIdentifier.components(separatedBy: "(").first ?? gateIdentifier
            var parameter: String? = nil

            if let paramStart = gateIdentifier.firstIndex(of: "("), let paramEnd = gateIdentifier.lastIndex(of: ")") {
                let start = gateIdentifier.index(after: paramStart)
                let rawParameter = String(gateIdentifier[start..<paramEnd])
                // Run the extracted parameter through the formatter before saving it
                // We don't want full precision float numbers after all
                parameter = formatParameter(rawParameter)
            }

            let involvedQubits = extractAllIntegers(from: qubitsPart)
            guard !involvedQubits.isEmpty else { continue }

            // Find the column where this gate should sit
            let moment = involvedQubits.compactMap { currentMomentPerWire[$0] }.max() ?? 0

            if involvedQubits.count == 1 {
                operations.append(CircuitOperation(type: .singleQubit(target: involvedQubits[0], label: gateName, parameter: parameter), momentIndex: moment))
            } else if involvedQubits.count == 2 {
                operations.append(CircuitOperation(type: .multiQubit(control: involvedQubits[0], target: involvedQubits[1], label: gateName), momentIndex: moment))
            } else {
                operations.append(CircuitOperation(type: .nQubit(qubits: involvedQubits, label: gateName), momentIndex: moment))
            }

            // Push all involved wires to the same timeline position
            for q in involvedQubits { currentMomentPerWire[q] = moment + 1 }
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

            case .nQubit(let qubits, let label):
                mappedType = .nQubit(qubits: qubits.compactMap { physicalToVisualMap[$0] }, label: label)

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
    private static func extractAllIntegers(from string: String) -> [Int] {
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
