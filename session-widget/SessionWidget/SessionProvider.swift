import SessionCore
import WidgetKit

struct SessionEntry: TimelineEntry {
    enum Content {
        case loaded(SessionsFile)
        case noData
        case needsUpdate
    }

    let date: Date
    let content: Content
}

struct SessionProvider: TimelineProvider {
    func placeholder(in context: Context) -> SessionEntry {
        SessionEntry(date: Date(), content: .loaded(SampleData.file))
    }

    func getSnapshot(in context: Context, completion: @escaping (SessionEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SessionEntry>) -> Void) {
        // The host reloads on change. This is only the backstop.
        let next = Date().addingTimeInterval(5 * 60)
        completion(Timeline(entries: [currentEntry()], policy: .after(next)))
    }

    private func currentEntry() -> SessionEntry {
        switch SharedStorage.load() {
        case .success(let file): return SessionEntry(date: Date(), content: .loaded(file))
        case .failure(.unknownSchema): return SessionEntry(date: Date(), content: .needsUpdate)
        case .failure: return SessionEntry(date: Date(), content: .noData)
        }
    }
}
