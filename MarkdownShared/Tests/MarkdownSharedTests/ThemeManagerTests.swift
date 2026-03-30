import XCTest
@testable import MarkdownShared

final class ThemeManagerTests: XCTestCase {

    // MARK: - Theme Enum

    func testAllThemesHaveDisplayNames() {
        for theme in Theme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty, "\(theme.rawValue) has empty display name")
        }
    }

    func testAllThemesHaveCSSFilenames() {
        for theme in Theme.allCases {
            XCTAssertTrue(theme.cssFilename.hasSuffix(".css"))
        }
    }

    func testThemeIsDark() {
        XCTAssertFalse(Theme.githubLight.isDark)
        XCTAssertTrue(Theme.githubDark.isDark)
        XCTAssertTrue(Theme.dracula.isDark)
        XCTAssertTrue(Theme.nord.isDark)
    }

    func testThemeRawValues() {
        XCTAssertEqual(Theme.githubLight.rawValue, "github-light")
        XCTAssertEqual(Theme.githubDark.rawValue, "github-dark")
        XCTAssertEqual(Theme.dracula.rawValue, "dracula")
        XCTAssertEqual(Theme.nord.rawValue, "nord")
    }

    // MARK: - CSS Loading

    func testLoadGitHubLightCSS() throws {
        let css = try ThemeManager.shared.loadCSS(for: .githubLight)
        XCTAssertTrue(css.contains(".markdown-body"))
        XCTAssertTrue(css.contains("background-color"))
    }

    func testLoadGitHubDarkCSS() throws {
        let css = try ThemeManager.shared.loadCSS(for: .githubDark)
        XCTAssertTrue(css.contains(".markdown-body"))
        XCTAssertTrue(css.contains("#0d1117")) // dark background
    }

    func testLoadDraculaCSS() throws {
        let css = try ThemeManager.shared.loadCSS(for: .dracula)
        XCTAssertTrue(css.contains(".markdown-body"))
        XCTAssertTrue(css.contains("#282a36")) // dracula background
    }

    func testLoadNordCSS() throws {
        let css = try ThemeManager.shared.loadCSS(for: .nord)
        XCTAssertTrue(css.contains(".markdown-body"))
        XCTAssertTrue(css.contains("#2e3440")) // nord background
    }

    func testAllThemeCSSLoadable() throws {
        for theme in Theme.allCases {
            let css = try ThemeManager.shared.loadCSS(for: theme)
            XCTAssertFalse(css.isEmpty, "CSS for \(theme.rawValue) should not be empty")
            XCTAssertTrue(css.contains(".markdown-body"), "CSS for \(theme.rawValue) must style .markdown-body")
        }
    }

    // MARK: - Theme Selection

    func testSelectedThemeOverride() {
        let manager = ThemeManager.shared
        let original = manager.selectedTheme

        manager.selectedTheme = .dracula
        XCTAssertEqual(manager.effectiveTheme, .dracula)

        manager.selectedTheme = .nord
        XCTAssertEqual(manager.effectiveTheme, .nord)

        // Restore
        manager.selectedTheme = original
    }

    func testEffectiveThemeAutoDetectsWhenNil() {
        let manager = ThemeManager.shared
        let original = manager.selectedTheme

        manager.selectedTheme = nil
        // Should return either githubLight or githubDark based on system
        let theme = manager.effectiveTheme
        XCTAssertTrue(theme == .githubLight || theme == .githubDark)

        manager.selectedTheme = original
    }

    // MARK: - Supported Themes

    func testSupportedThemesCount() {
        XCTAssertEqual(ThemeManager.supportedThemes.count, 4)
    }

    func testSupportedThemesContainsAll() {
        for theme in Theme.allCases {
            XCTAssertTrue(ThemeManager.supportedThemes.contains(theme))
        }
    }

    // MARK: - Theme Codable

    func testThemeCodable() throws {
        let theme = Theme.dracula
        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(Theme.self, from: data)
        XCTAssertEqual(decoded, theme)
    }
}
