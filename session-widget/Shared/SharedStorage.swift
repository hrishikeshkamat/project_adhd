import Foundation
import SessionCore

enum SharedStorage {
    static var fileURL: URL? {
        switch AppConfig.storage {
        case .appGroup:
            return FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID)?
                .appendingPathComponent(AppConfig.fileName)
        case .applicationSupport:
            // Real home, because the sandboxed widget's home points at its container.
            return RealHome.url
                .appendingPathComponent("Library/Application Support/SessionBoard", isDirectory: true)
                .appendingPathComponent(AppConfig.fileName)
        }
    }

    enum LoadError: Error {
        case noLocation
        case missing
        case unknownSchema
        case unreadable
    }

    static func load() -> Result<SessionsFile, LoadError> {
        guard let url = fileURL else { return .failure(.noLocation) }
        guard let data = try? Data(contentsOf: url) else { return .failure(.missing) }
        do {
            return .success(try SessionsFile.decode(data))
        } catch SessionsFileError.unknownSchemaVersion {
            return .failure(.unknownSchema)
        } catch {
            return .failure(.unreadable)
        }
    }
}
