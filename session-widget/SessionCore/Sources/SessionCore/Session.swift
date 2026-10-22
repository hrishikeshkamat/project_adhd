import Foundation

public struct Session: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let source: String
    public let projectName: String
    public let projectPath: String
    public let lastPrompt: String?
    public let lastActivity: Date
    public let openURL: URL

    public init(
        id: String,
        source: String,
        projectName: String,
        projectPath: String,
        lastPrompt: String?,
        lastActivity: Date,
        openURL: URL
    ) {
        self.id = id
        self.source = source
        self.projectName = projectName
        self.projectPath = projectPath
        self.lastPrompt = lastPrompt
        self.lastActivity = lastActivity
        self.openURL = openURL
    }

    /// Copy with the prompt removed. Privacy is applied before writing, not in views.
    public func withoutPrompt() -> Session {
        Session(id: id, source: source, projectName: projectName, projectPath: projectPath,
                lastPrompt: nil, lastActivity: lastActivity, openURL: openURL)
    }
}
