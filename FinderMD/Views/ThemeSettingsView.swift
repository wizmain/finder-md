import SwiftUI
import MarkdownShared

struct ThemeSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Picker("Theme", selection: $settings.selectedTheme) {
                Text("Auto (System)").tag(Theme?.none)
                ForEach(ThemeManager.supportedThemes, id: \.self) { theme in
                    HStack {
                        ThemeSwatchView(theme: theme)
                        Text(theme.displayName)
                    }
                    .tag(Theme?.some(theme))
                }
            }
            .pickerStyle(.radioGroup)

            GroupBox("Current") {
                let effective = settings.selectedTheme ?? ThemeManager.shared.effectiveTheme
                HStack {
                    ThemeSwatchView(theme: effective)
                    Text(effective.displayName)
                    if settings.selectedTheme == nil {
                        Text("(auto-detected)")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(4)
            }
        }
        .padding()
        .navigationTitle("Theme")
    }
}

/// Small color swatch showing a theme's background and text color.
private struct ThemeSwatchView: View {
    let theme: Theme

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(backgroundColor)
            .overlay(
                Text("A")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(textColor)
            )
            .frame(width: 20, height: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
    }

    private var backgroundColor: Color {
        switch theme {
        case .githubLight: return Color(nsColor: .white)
        case .githubDark:  return Color(red: 0.051, green: 0.067, blue: 0.090)
        case .dracula:     return Color(red: 0.157, green: 0.165, blue: 0.212)
        case .nord:        return Color(red: 0.180, green: 0.204, blue: 0.251)
        }
    }

    private var textColor: Color {
        switch theme {
        case .githubLight: return Color(red: 0.122, green: 0.137, blue: 0.157)
        case .githubDark:  return Color(red: 0.902, green: 0.929, blue: 0.953)
        case .dracula:     return Color(red: 0.973, green: 0.973, blue: 0.949)
        case .nord:        return Color(red: 0.847, green: 0.871, blue: 0.914)
        }
    }
}
