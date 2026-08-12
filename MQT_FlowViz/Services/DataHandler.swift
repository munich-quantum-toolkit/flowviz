//
//  DataHandler.swift
//  MQT_FlowViz
//
//  Created by Linus Bohle on 24.04.26.
//
import Foundation
import SwiftUI
import SwiftData
import OSLog

class DataHandler {
    /// Enumeration containing all possible errors occuring together with the ``DataHandler`` class.
    ///
    /// All enumerations are accompanied by an associated string value, which should be a user-friendly error message
    /// describing what went wrong.
    enum DataError: LocalizedError {
        case AccessFailed(String)
        case DecodingError(String)
        case EncodingError(String)

        var errorDescription: String? {
            switch self {
            case .AccessFailed(let message): return message
            case .DecodingError(let message): return message
            case .EncodingError(let message): return message
            }
        }
    }

    static let logger: Logger = Logger(subsystem: "DataHandling", category: "DataHandler")

    /// Parses a JSON file from a given URL and adds it to the traces array.
    /// - Parameter url: the URL of the file that should be parsed.
    /// - Parameter into: the ``ModelContext`` into which the imported trace should be added.
    static func importTrace(from url: URL, into context: ModelContext) throws {
        // Security wrapper required for accessing files outside the app's immediate sandbox (like Finder/Files app)
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to access security scoped resource: \(url.path)")
            throw DataError.AccessFailed("Failed to access security scoped resource.")
        }

        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let newTrace = try decoder.decode(CompilationTrace.self, from: data)

            context.insert(newTrace)
            try context.save()

            logger.info("Successfully imported: \(newTrace.circuitName) from \(url.path)")
        } catch {
            logger.error("Failed to decode trace JSON: \(error)")
            throw DataError.DecodingError("Failed to decode trace JSON: \(error)")
        }
    }

    
    /// Exports the provided trace to a temporary URL for later transfer.
    /// - Parameter trace: The trace to be exported.
    /// - Returns: The temporary URL at which the exported trace is located.
    static func generateExportURL(for trace: CompilationTrace) throws -> URL {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(trace)

            // Sanitize the circuit name to ensure a valid filename
            let safeName = trace.circuitName
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "-")

            // Write the file to the app's temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("\(safeName).json")

            try data.write(to: fileURL, options: .atomic)
            return fileURL

        } catch {
            logger.error("Failed to encode export JSON: \(error)")
            throw DataError.EncodingError("Failed to encode trace: \(error)")
        }
    }
}
