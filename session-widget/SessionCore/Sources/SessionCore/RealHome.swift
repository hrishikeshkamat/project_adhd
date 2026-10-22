import Foundation

/// The user's real home folder. In a sandbox `homeDirectoryForCurrentUser` points at the container.
public enum RealHome {
    public static var url: URL {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir), isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }
}
