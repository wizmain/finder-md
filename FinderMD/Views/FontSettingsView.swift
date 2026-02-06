import SwiftUI

struct FontSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 8) {
                Text("Font Size: \(Int(settings.fontSize))")
                Slider(value: $settings.fontSize, in: 12...24, step: 1)
            }
        }
        .navigationTitle("Font")
    }
}
