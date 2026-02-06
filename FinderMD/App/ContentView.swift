import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("Extension Status") {
                    ExtensionStatusView()
                }
                NavigationLink("Theme") {
                    ThemeSettingsView()
                }
                NavigationLink("Font") {
                    FontSettingsView()
                }
            }
            .navigationTitle("Finder MD")
        } detail: {
            Text("Select a setting")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}
