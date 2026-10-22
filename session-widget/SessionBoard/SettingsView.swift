import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Hide prompt text", isOn: $model.hideSnippets)
            Toggle("One row per project", isOn: $model.collapseByProject)
            Toggle("Launch at login", isOn: Binding(
                get: { model.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))
        }
        .toggleStyle(.checkbox)
    }
}
