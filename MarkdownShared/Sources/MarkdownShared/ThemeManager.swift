import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Supported CSS themes.
public enum Theme: String, CaseIterable, Sendable, Codable {
    case githubLight = "github-light"
    case githubDark = "github-dark"
    case dracula = "dracula"
    case nord = "nord"

    public var displayName: String {
        switch self {
        case .githubLight: return "GitHub Light"
        case .githubDark: return "GitHub Dark"
        case .dracula: return "Dracula"
        case .nord: return "Nord"
        }
    }

    public var cssFilename: String {
        return rawValue + ".css"
    }

    /// Whether this is a dark theme.
    public var isDark: Bool {
        switch self {
        case .githubLight: return false
        case .githubDark, .dracula, .nord: return true
        }
    }
}

/// Manages CSS themes and system appearance detection.
public final class ThemeManager: @unchecked Sendable {

    public static let shared = ThemeManager()

    /// User-selected theme override. When `nil`, theme is auto-detected from system appearance.
    public var selectedTheme: Theme?

    /// Returns the theme to use: user selection if set, otherwise auto-detected.
    public var effectiveTheme: Theme {
        if let selected = selectedTheme {
            return selected
        }
        return Self.systemIsDarkMode ? .githubDark : .githubLight
    }

    private init() {}

    /// Loads the CSS content for a given theme from the bundle.
    public func loadCSS(for theme: Theme) throws -> String {
        guard let url = Bundle.module.url(
            forResource: theme.rawValue,
            withExtension: "css",
            subdirectory: "themes"
        ) else {
            throw ThemeError.themeNotFound(theme.rawValue)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// Loads the CSS for the effective theme.
    public func loadEffectiveCSS() throws -> String {
        return try loadCSS(for: effectiveTheme)
    }

    /// All available themes.
    public static let supportedThemes: [Theme] = Theme.allCases

    // MARK: - System Appearance Detection

    /// Detects whether the system is in dark mode.
    public static var systemIsDarkMode: Bool {
        #if canImport(AppKit)
        let appearance = NSAppearance.currentDrawing()
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark
        #else
        return false
        #endif
    }
}

/// Errors related to theme loading.
public enum ThemeError: Error, LocalizedError {
    case themeNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .themeNotFound(let name):
            return "Theme CSS file not found: \(name)"
        }
    }
}
