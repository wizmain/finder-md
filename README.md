# FinderMD

macOS Finder Quick Look extension for beautifully rendered Markdown and HWPX document previews — right from Finder.

## Features

### Markdown Preview
- **GitHub Flavored Markdown** — tables, task lists, strikethrough, autolinks
- **Syntax Highlighting** — 30+ languages via highlight.js
- **Mermaid Diagrams** — flowcharts, sequence diagrams, Gantt charts, and more
- **KaTeX Math** — inline and display math expressions
- **Image Embedding** — local (including `../` relative paths) and remote images resolved and embedded inline

### HWPX Preview (한컴 문서)
- **HWPX 파일 미리보기** — 한컴오피스 한글 문서를 Finder에서 바로 미리보기
- **스타일 렌더링** — 굵기, 기울임, 폰트 크기, 색상, 정렬
- **테이블 지원** — 셀 병합 포함
- **이미지 임베딩** — BinData 이미지를 base64로 인라인 렌더링
- **다중 섹션** — 여러 섹션으로 구성된 문서 지원

### 공통
- **4 Themes** — github-light, github-dark, dracula, nord
- **Dark Mode** — automatically follows system appearance
- **Thumbnail Generation** — file thumbnails in Finder

## System Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.2+ (for development)
- Swift 5.10

## Installation

1. Download the latest `.dmg` from [Releases](https://github.com/wizmain/finder-md/releases)
2. Open the DMG and drag **Finder MD.app** to `/Applications`
3. Launch **Finder MD** once to register the extensions
4. Enable the extensions:
   - Open **System Settings → Privacy & Security → Extensions → Quick Look**
   - Toggle **Finder MD** on

## Project Structure

```
finder-md/
├── scripts/
│   ├── build-release.sh              # Release build & DMG packaging
│   └── ExportOptions.plist           # Code signing export options
├── project.yml                       # XcodeGen project configuration
├── FinderMD/                         # Companion App (SwiftUI)
│   ├── App/                          #   App entry point & main view
│   ├── Models/                       #   Settings model
│   └── Views/                        #   Preview, theme, font settings
├── QuickLookExtension/               # Markdown Quick Look Extension
│   └── PreviewViewController.swift
├── ThumbnailExtension/               # Markdown Thumbnail Extension
│   └── ThumbnailProvider.swift
├── HWPXQuickLookExtension/           # HWPX Quick Look Extension
│   └── HWPXPreviewProvider.swift
├── HWPXThumbnailExtension/           # HWPX Thumbnail Extension
│   └── HWPXThumbnailProvider.swift
├── MarkdownShared/                   # Shared Markdown Package (SPM)
│   ├── Package.swift
│   ├── Sources/MarkdownShared/
│   │   ├── MarkdownParser.swift      #   Markdown → HTML conversion
│   │   ├── HTMLRenderer.swift        #   Full HTML document rendering
│   │   ├── ImageResolver.swift       #   Image path resolution & embedding
│   │   ├── ThemeManager.swift        #   Theme loading & dark mode
│   │   └── Resources/               #   template, themes, JS, CSS, fonts
│   └── Tests/MarkdownSharedTests/
└── HWPXShared/                       # Shared HWPX Package (SPM)
    ├── Package.swift
    ├── Sources/HWPXShared/
    │   ├── HWPXParser.swift          #   Entry point: ZIP → parse → HTML
    │   ├── HWPXArchive.swift         #   ZIP reading (ZIPFoundation)
    │   ├── HWPXDocument.swift        #   Document model types
    │   ├── SectionParser.swift       #   Section XML → document model
    │   ├── HeaderParser.swift        #   Header XML → styles & fonts
    │   └── HWPXHTMLGenerator.swift   #   Document model → HTML
    └── Tests/HWPXSharedTests/
```

### Targets

| Target | Type | Bundle ID | Description |
|---|---|---|---|
| **FinderMD** | App | `com.findermd.app` | Companion app for settings & extension management |
| **QuickLookExtension** | App Extension | `com.findermd.app.quicklook` | Renders Markdown preview on Spacebar |
| **ThumbnailExtension** | App Extension | `com.findermd.app.thumbnail` | Generates Markdown thumbnails in Finder |
| **HWPXQuickLookExtension** | App Extension | `com.findermd.app.hwpx-quicklook` | Renders HWPX preview on Spacebar |
| **HWPXThumbnailExtension** | App Extension | `com.findermd.app.hwpx-thumbnail` | Generates HWPX thumbnails in Finder |
| **MarkdownShared** | SPM Package | — | Shared Markdown parsing & rendering library |
| **HWPXShared** | SPM Package | — | Shared HWPX parsing & rendering library |

## Development

### Prerequisites

- [Xcode 16.2+](https://developer.apple.com/xcode/)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

### Build

```bash
# Generate Xcode project
xcodegen generate

# Open in Xcode
open FinderMD.xcodeproj

# Build & run (Cmd+R in Xcode)
```

### Run Tests

```bash
# Markdown tests (75 tests)
swift test --package-path MarkdownShared

# HWPX tests (33 tests)
swift test --package-path HWPXShared
```

### Testing Quick Look Extensions

> `qlmanage -p` does **not** work with data-based Quick Look extensions. You must test via Finder.

1. Build and run the app from Xcode
2. Open Finder and navigate to a `.md` or `.hwpx` file
3. Press **Spacebar** to trigger Quick Look preview

To force-reload after rebuilding:
```bash
qlmanage -r
killall Finder
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

| Package | Purpose |
|---|---|
| [swift-markdown](https://github.com/swiftlang/swift-markdown) | Apple's Swift Markdown parser |
| [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) | HWPX ZIP archive reading |
| [highlight.js](https://highlightjs.org/) | Syntax highlighting |
| [Mermaid](https://mermaid.js.org/) | Diagram rendering |
| [KaTeX](https://katex.org/) | Math typesetting |

## License

<!-- TODO: Add license -->

TBD
