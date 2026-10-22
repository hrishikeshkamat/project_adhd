import Foundation

/// The subset of a transcript line the widget needs. Parsed loosely so unknown fields never break it.
struct TranscriptRecord {
    let type: String?
    let cwd: String?
    let sessionId: String?
    let timestamp: Date?
    let isSidechain: Bool
    let isMeta: Bool
    /// Joined text blocks of a user message, nil when there is no text (for example tool results only).
    let userText: String?

    init?(line: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else {
            return nil
        }
        type = object["type"] as? String
        cwd = object["cwd"] as? String
        sessionId = object["sessionId"] as? String
        timestamp = (object["timestamp"] as? String).flatMap(TranscriptDate.parse)
        isSidechain = object["isSidechain"] as? Bool ?? false
        isMeta = object["isMeta"] as? Bool ?? false

        let message = object["message"] as? [String: Any]
        let content = message?["content"]
        if let text = content as? String {
            userText = text
        } else if let blocks = content as? [[String: Any]] {
            let texts = blocks.compactMap { block -> String? in
                guard block["type"] as? String == "text" else { return nil }
                return block["text"] as? String
            }
            userText = texts.isEmpty ? nil : texts.joined(separator: " ")
        } else {
            userText = nil
        }
    }
}

enum TranscriptDate {
    private static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain = ISO8601DateFormatter()

    static func parse(_ string: String) -> Date? {
        fractional.date(from: string) ?? plain.date(from: string)
    }
}
