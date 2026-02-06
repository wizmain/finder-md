import SwiftUI

struct ExtensionStatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Look and Thumbnail extensions are managed in System Settings.")
            Link("Open Extensions Settings", destination: URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .navigationTitle("Extension Status")
    }
}
