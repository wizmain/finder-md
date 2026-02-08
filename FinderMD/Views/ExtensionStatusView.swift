import SwiftUI

struct ExtensionStatusView: View {
    var body: some View {
        Form {
            Section("Quick Look Extension") {
                HStack {
                    Label("Markdown Preview", systemImage: "eye")
                    Spacer()
                    Text("Managed by System")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Thumbnail Extension") {
                HStack {
                    Label("Markdown Thumbnails", systemImage: "photo")
                    Spacer()
                    Text("Managed by System")
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Text("Extensions are enabled and disabled in System Settings. Click the button below to open the Extensions preference pane.")
                    .foregroundStyle(.secondary)
                Link(destination: URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!) {
                    Label("Open Extensions Settings", systemImage: "gear")
                }
            }
        }
        .padding()
        .navigationTitle("Extension Status")
    }
}
