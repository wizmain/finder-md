import Foundation

enum Theme: String, CaseIterable {
    case githubLight = "github-light"
    case githubDark = "github-dark"
    case dracula
    case nord

    var displayName: String {
        switch self {
        case .githubLight: return "GitHub Light"
        case .githubDark: return "GitHub Dark"
        case .dracula: return "Dracula"
        case .nord: return "Nord"
        }
    }

    var cssFileName: String {
        "\(rawValue).css"
    }
}

struct ThemeManager {
    static let supportedThemes = Theme.allCases

    func resolveTheme(forInterfaceStyle isDarkMode: Bool) -> Theme {
        isDarkMode ? .githubDark : .githubLight
    }
}
