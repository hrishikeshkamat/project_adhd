import Foundation
import SessionCore
import WidgetKit

/// Writes `sessions.json` for the widget and reloads it, but only when the content changed.
final class SessionsWriter {
    enum WriteError: Error {
        case noLocation
        case createFailed
        case renameFailed(Int32)
    }

    private var lastWritten: SessionsFile?

    init() {
        if case .success(let existing) = SharedStorage.load() { lastWritten = existing }
    }

    @discardableResult
    func writeIfChanged(_ file: SessionsFile) throws -> Bool {
        if let lastWritten, lastWritten.hasSameContent(as: file) { return false }
        guard let url = SharedStorage.fileURL else { throw WriteError.noLocation }
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])

        // Temp file is created 0600 so the snippet text is never briefly world-readable.
        let temp = dir.appendingPathComponent(".\(AppConfig.fileName).\(UUID().uuidString)")
        guard FileManager.default.createFile(atPath: temp.path, contents: try file.encoded(),
                                             attributes: [.posixPermissions: 0o600]) else {
            throw WriteError.createFailed
        }
        if rename(temp.path, url.path) != 0 {
            let code = errno
            try? FileManager.default.removeItem(at: temp)
            throw WriteError.renameFailed(code)
        }
        lastWritten = file
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.widgetKind)
        return true
    }
}
