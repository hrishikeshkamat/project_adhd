import Foundation

public enum DeepLink {
    // RFC 3986 unreserved set. Everything else is percent-encoded, including "/" and non-ASCII.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    /// Opens a new Code session in `folder`. Only the folder is ever passed, never prompt text.
    public static func codeSession(folder: String) -> URL {
        let encoded = folder.addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
        // Force unwrap is safe: the string is ASCII and fully encoded.
        return URL(string: "claude://code/new?folder=\(encoded)")!
    }
}
