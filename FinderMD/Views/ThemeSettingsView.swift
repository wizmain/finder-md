import SwiftUI

struct ThemeSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Picker("Theme", selection: $settings.selectedTheme) {
                ForEach(ThemeManager.supportedThemes, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
        }
        .navigationTitle("Theme")
    }
}
