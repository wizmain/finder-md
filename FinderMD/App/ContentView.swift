import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Section("Settings") {
                    NavigationLink {
                        ThemeSettingsView()
                    } label: {
                        Label("Theme", systemImage: "paintbrush")
                    }
                    NavigationLink {
                        FontSettingsView()
                    } label: {
                        Label("Font", systemImage: "textformat.size")
                    }
                }
                Section("Extensions") {
                    NavigationLink {
                        ExtensionStatusView()
                    } label: {
                        Label("Extension Status", systemImage: "puzzlepiece.extension")
                    }
                }
                Section("Preview") {
                    NavigationLink {
                        PreviewView()
                    } label: {
                        Label("Markdown Preview", systemImage: "doc.richtext")
                    }
                }
            }
            .navigationTitle("Finder MD")
        } detail: {
            PreviewView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}
