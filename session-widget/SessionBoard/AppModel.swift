import Foundation
import ServiceManagement
import SessionCore
import os

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var file: SessionsFile?
    @Published private(set) var problem: String?

    @Published var hideSnippets: Bool {
        didSet { defaults.set(hideSnippets, forKey: Keys.hideSnippets); scheduleScan() }
    }
    @Published var collapseByProject: Bool {
        didSet { defaults.set(collapseByProject, forKey: Keys.collapseByProject); scheduleScan() }
    }
    @Published private(set) var launchAtLogin: Bool

    private enum Keys {
        static let hideSnippets = "hideSnippets"
        static let collapseByProject = "collapseByProject"
    }

    private let defaults = UserDefaults.standard
    private let log = Logger(subsystem: AppConfig.logSubsystem, category: "scan")
    private let source = ClaudeCodeSource(projectsRoot: ClaudeCodeSource.defaultRoot())
    private let writer = SessionsWriter()
    private var watcher: TranscriptWatcher?
    private var timer: Timer?
    private var pendingScan: Task<Void, Never>?

    init() {
        hideSnippets = defaults.bool(forKey: Keys.hideSnippets)
        collapseByProject = defaults.bool(forKey: Keys.collapseByProject)
        launchAtLogin = SMAppService.mainApp.status == .enabled
        start()
    }

    private func start() {
        let watcher = TranscriptWatcher(path: source.projectsRoot.path) { [weak self] in
            Task { @MainActor in self?.scheduleScan() }
        }
        watcher.start()
        self.watcher = watcher
        // Backstop for missed events and for `~/.claude` appearing after launch.
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.scheduleScan() }
        }
        scheduleScan(delay: 0)
    }

    /// Coalesces bursts of file events into one scan.
    func scheduleScan(delay: Duration = .seconds(1)) {
        pendingScan?.cancel()
        pendingScan = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.scan()
        }
    }

    private func scan() async {
        let source = self.source
        let hide = hideSnippets
        let collapse = collapseByProject
        let started = Date()
        let result: Result<SessionsFile, Error> = await Task.detached(priority: .utility) {
            Result {
                var sessions = try source.recentSessions(limit: SessionsFile.maxEntries)
                if collapse { sessions = SessionRanking.collapseByProject(sessions) }
                return SessionsFile(generatedAt: Date(), hideSnippets: hide, sessions: sessions)
            }
        }.value

        switch result {
        case .success(let newFile):
            file = newFile
            problem = FileManager.default.fileExists(atPath: source.projectsRoot.path)
                ? nil : "No ~/.claude/projects folder yet"
            do {
                let changed = try writer.writeIfChanged(newFile)
                let ms = Int(Date().timeIntervalSince(started) * 1000)
                log.debug("scan \(newFile.sessions.count, privacy: .public) sessions, \(ms, privacy: .public) ms, changed \(changed, privacy: .public)")
            } catch {
                problem = "Could not write sessions.json"
                log.error("write failed: \(String(describing: error), privacy: .private)")
            }
        case .failure(let error):
            problem = "Could not read ~/.claude/projects"
            log.error("scan failed: \(String(describing: error), privacy: .private)")
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            log.error("login item change failed: \(String(describing: error), privacy: .private)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
