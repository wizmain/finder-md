import Combine
import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let selectedTheme = "selectedTheme"
        static let fontSize = "fontSize"
    }

    @Published var selectedTheme: Theme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Keys.selectedTheme)
        }
    }

    @Published var fontSize: Double {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: Keys.fontSize)
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.selectedTheme),
           let theme = Theme(rawValue: raw) {
            selectedTheme = theme
        } else {
            selectedTheme = .githubLight
        }

        let storedSize = UserDefaults.standard.double(forKey: Keys.fontSize)
        fontSize = storedSize == 0 ? 14 : storedSize
    }
}
