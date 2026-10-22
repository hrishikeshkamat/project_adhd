import SwiftUI

@main
struct SessionBoardApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("SessionBoard", systemImage: "clock.arrow.circlepath") {
            PopoverView()
                .environmentObject(model)
        }
        .menuBarExtraStyle(.window)
    }
}
