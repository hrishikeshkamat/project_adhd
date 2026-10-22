import Foundation

public protocol SessionSource {
    var id: String { get }
    func recentSessions(limit: Int) throws -> [Session]
}
