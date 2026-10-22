import Foundation

/// Bounded reads so large transcripts are never loaded whole.
enum FileTail {
    static func head(of url: URL, bytes: Int) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try handle.read(upToCount: bytes) ?? Data()
    }

    /// Returns the last `bytes` of the file. Drops the first partial line when the read starts mid-file.
    static func tail(of url: URL, bytes: Int) throws -> (data: Data, isWholeFile: Bool) {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let size = try handle.seekToEnd()
        let start = size > UInt64(bytes) ? size - UInt64(bytes) : 0
        try handle.seek(toOffset: start)
        var data = try handle.readToEnd() ?? Data()
        if start > 0, let newline = data.firstIndex(of: 0x0A) {
            data = data.subdata(in: data.index(after: newline)..<data.endIndex)
        }
        return (data, start == 0)
    }

    static func lines(in data: Data) -> [Data] {
        data.split(separator: 0x0A, omittingEmptySubsequences: true).map { Data($0) }
    }
}
