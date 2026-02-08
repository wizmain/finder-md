# FinderMD

macOS Finder Quick Look extension for beautifully rendered Markdown previews — right from Finder.

## Features

- **GitHub Flavored Markdown** — tables, task lists, strikethrough, autolinks
- **Syntax Highlighting** — 30+ languages via highlight.js
- **Mermaid Diagrams** — flowcharts, sequence diagrams, Gantt charts, and more
- **KaTeX Math** — inline and display math expressions
- **4 Themes** — github-light, github-dark, dracula, nord
- **Dark Mode** — automatically follows system appearance
- **Thumbnail Generation** — Markdown file thumbnails in Finder
- **Image Embedding** — local and remote images resolved and embedded inline

## Screenshots

<!-- TODO: Add screenshots -->

| Quick Look Preview | Thumbnail | Companion App |
|---|---|---|
| ![Preview](docs/screenshots/preview.png) | ![Thumbnail](docs/screenshots/thumbnail.png) | ![App](docs/screenshots/app.png) |

## System Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.2+ (for development)
- Swift 5.10

## Installation

1. Download the latest `.dmg` from [Releases](https://github.com/user/finder-md/releases)
2. Open the DMG and drag **Finder MD.app** to `/Applications`
3. Launch **Finder MD** once to register the extensions
4. Enable the extensions:
   - Open **System Settings → Privacy & Security → Extensions → Quick Look**
   - Toggle **Finder MD** on

## Project Structure

```
finder-md/
├── scripts/
│   ├── build-release.sh          # Release build & DMG packaging
│   └── ExportOptions.plist       # Code signing export options
└── agent-claude-code/
    ├── project.yml               # XcodeGen project configuration
    ├── FinderMD/                 # Companion App (SwiftUI)
    │   ├── App/                  #   App entry point & main view
    │   ├── Models/               #   Settings model
    │   └── Views/                #   Preview, theme, font settings
    ├── QuickLookExtension/       # Quick Look Preview Extension
    │   └── PreviewViewController.swift
    ├── ThumbnailExtension/       # Thumbnail Generation Extension
    │   └── ThumbnailProvider.swift
    └── MarkdownShared/           # Shared Swift Package
        ├── Package.swift
        ├── Sources/MarkdownShared/
        │   ├── MarkdownParser.swift    # Markdown → HTML conversion
        │   ├── HTMLRenderer.swift      # Full HTML document rendering
        │   ├── ImageResolver.swift     # Image path resolution & embedding
        │   ├── ThemeManager.swift      # Theme loading & dark mode
        │   └── Resources/
        │       ├── template.html       # HTML template
        │       ├── themes/             # 4 CSS theme files
        │       ├── js/                 # highlight.js, mermaid.js, katex.js
        │       ├── css/                # Syntax & math stylesheets
        │       └── fonts/              # KaTeX woff2 fonts
        └── Tests/MarkdownSharedTests/
```

### Targets

| Target | Type | Bundle ID | Description |
|---|---|---|---|
| **FinderMD** | App | `com.findermd.app` | Companion app for settings & extension management |
| **QuickLookExtension** | App Extension | `com.findermd.app.quicklook` | Renders Markdown preview on Spacebar |
| **ThumbnailExtension** | App Extension | `com.findermd.app.thumbnail` | Generates Finder thumbnail icons |
| **MarkdownShared** | SPM Package | — | Shared Markdown parsing & rendering library |

## Development

### Prerequisites

- [Xcode 16.2+](https://developer.apple.com/xcode/)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

### Build

```bash
cd agent-claude-code

# Generate Xcode project
xcodegen generate

# Open in Xcode
open FinderMD.xcodeproj

# Build & run (Cmd+R in Xcode)
```

### Run Tests

```bash
cd agent-claude-code/MarkdownShared
swift test
```

### Testing Quick Look Extension

> `qlmanage -p` does **not** work with data-based Quick Look extensions. You must test via Finder.

1. Build and run the app from Xcode
2. Open Finder and navigate to a `.md` file
3. Press **Spacebar** to trigger Quick Look preview

To force-reload after rebuilding:
```bash
killall QuickLookExtension 2>/dev/null; killall Finder
```

## Release Build

The `build-release.sh` script automates archiving, code signing, and DMG packaging.

```bash
# Unsigned build (for local testing)
./scripts/build-release.sh

# Developer ID signed
./scripts/build-release.sh --sign

# Signed + notarized (for distribution)
./scripts/build-release.sh --sign --notarize
```

Output: `build/release/FinderMD-{VERSION}.dmg`

## Themes

FinderMD ships with 4 built-in themes:

| Theme | Description |
|---|---|
| **github-light** | GitHub-style light theme (default) |
| **github-dark** | GitHub-style dark theme |
| **dracula** | Popular dark theme with vibrant colors |
| **nord** | Arctic-inspired pastel dark theme |

The active theme automatically switches between light/dark variants based on the system appearance setting.

## Dependencies

- [swift-markdown](https://github.com/swiftlang/swift-markdown) — Apple's Swift Markdown parser
- [highlight.js](https://highlightjs.org/) — Syntax highlighting
- [Mermaid](https://mermaid.js.org/) — Diagram rendering
- [KaTeX](https://katex.org/) — Math typesetting

## License

<!-- TODO: Add license -->

TBD
