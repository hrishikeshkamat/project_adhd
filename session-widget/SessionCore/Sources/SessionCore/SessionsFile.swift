import Foundation

/// The JSON contract between the host app and the widget.
public struct SessionsFile: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let maxEntries = 30

    public let schemaVersion: Int
    public let generatedAt: Date
    public let hideSnippets: Bool
    public let sessions: [Session]

    public init(generatedAt: Date, hideSnippets: Bool, sessions: [Session]) {
        self.schemaVersion = Self.currentSchemaVersion
        self.generatedAt = generatedAt
        self.hideSnippets = hideSnippets
        let capped = Array(sessions.sorted { $0.lastActivity > $1.lastActivity }.prefix(Self.maxEntries))
        self.sessions = hideSnippets ? capped.map { $0.withoutPrompt() } : capped
    }

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public func encoded() throws -> Data {
        try Self.makeEncoder().encode(self)
    }

    /// Same content ignoring `generatedAt`, so unchanged scans skip the write and the widget reload.
    public func hasSameContent(as other: SessionsFile) -> Bool {
        schemaVersion == other.schemaVersion
            && hideSnippets == other.hideSnippets
            && sessions == other.sessions
    }
}

public enum SessionsFileError: Error, Equatable {
    case unknownSchemaVersion(Int)
}

extension SessionsFile {
    /// Decodes and rejects unknown schema versions instead of guessing.
    public static func decode(_ data: Data) throws -> SessionsFile {
        struct VersionProbe: Decodable { let schemaVersion: Int }
        let probe = try makeDecoder().decode(VersionProbe.self, from: data)
        guard probe.schemaVersion == currentSchemaVersion else {
            throw SessionsFileError.unknownSchemaVersion(probe.schemaVersion)
        }
        return try makeDecoder().decode(SessionsFile.self, from: data)
    }
}
