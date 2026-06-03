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

@Observable class DataHandler {
    /// Enumeration containing all possible errors occuring together with the ``DataHandler`` class.
    ///
    /// All enumerations are accompanied by an associated string value, which should be a user-friendly error message
    /// describing what went wrong.
    enum DataError: Error {
        case AccessFailed(String)
        case DecodingError(String)
    }

    let logger: Logger = Logger(subsystem: "DataHandling", category: "DataHandler")

    /// Parses a JSON file from a given URL and adds it to the traces array.
    /// - Parameter url: the URL of the file that should be parsed.
    /// - Parameter into: the ``ModelContext`` into which the imported trace should be added.
    func importTrace(from url: URL, into context: ModelContext) throws {
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
}

