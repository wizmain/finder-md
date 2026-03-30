import Combine
import Foundation
import MarkdownShared

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// App Group suite name for sharing settings with extensions.
    /// Configure this in Xcode under Signing & Capabilities → App Groups.
    static let suiteName = "group.com.findermd.shared"

    enum Keys {
        static let selectedTheme = "selectedTheme"
        static let fontSize = "fontSize"
    }

    private let defaults: UserDefaults

    /// Selected theme. `nil` means auto-detect from system appearance.
    @Published var selectedTheme: Theme? {
        didSet {
            defaults.set(selectedTheme?.rawValue, forKey: Keys.selectedTheme)
        }
    }

    @Published var fontSize: Double {
        didSet {
            defaults.set(fontSize, forKey: Keys.fontSize)
        }
    }

    private init() {
        defaults = UserDefaults(suiteName: AppSettings.suiteName) ?? .standard

        if let raw = defaults.string(forKey: Keys.selectedTheme),
           let theme = Theme(rawValue: raw) {
            selectedTheme = theme
        } else {
            selectedTheme = nil // auto-detect
        }

        let storedSize = defaults.double(forKey: Keys.fontSize)
        fontSize = storedSize == 0 ? 16 : storedSize
    }
}
