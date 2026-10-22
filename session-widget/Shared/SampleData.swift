import Foundation
import SessionCore

/// Synthetic data for previews only.
enum SampleData {
    static let sessions: [Session] = {
        let names = ["example-api", "firmware-gateway", "docs-site", "dashboard", "infra",
                     "mobile-app", "data-pipeline", "client-portal", "notes", "scratch", "ml-eval", "billing"]
        let prompts = ["Add retry with backoff to the upload client", "Fix the RS485 timeout on cold boot",
                       "Rewrite the install section", "Chart loads twice on first render", "Bump the base image",
                       "Crash on rotate in settings", "Dedupe rows before the nightly load", "Review the auth flow",
                       "Summarise the meeting notes", "Try a faster JSON parser", "Compare the two eval runs",
                       "Invoice totals off by rounding"]
        return names.enumerated().map { i, name in
            let path = "/Users/demo/dev/\(name)"
            return Session(id: "sample-\(i)", source: "claude-code", projectName: name, projectPath: path,
                           lastPrompt: prompts[i], lastActivity: Date().addingTimeInterval(Double(-i * 1500 - 120)),
                           openURL: DeepLink.codeSession(folder: path))
        }
    }()

    static let file = SessionsFile(generatedAt: Date(), hideSnippets: false, sessions: sessions)
    static let hiddenFile = SessionsFile(generatedAt: Date(), hideSnippets: true, sessions: sessions)
    static let staleFile = SessionsFile(generatedAt: Date().addingTimeInterval(-3600), hideSnippets: false, sessions: sessions)
}
