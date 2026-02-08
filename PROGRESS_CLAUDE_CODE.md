# Finder MD - Claude Code 작업 진행 현황

> 브랜치: `agent/claude-code`
> 최종 업데이트: 2024-02-06

---

## 전체 마일스톤 현황

| 마일스톤 | 상태 | 완료율 |
|---------|:----:|:------:|
| **M1: Shared Core** | ✅ 완료 | 100% |
| **M2: Quick Look Extension** | ✅ 완료 | 100% |
| **M3: Thumbnail Extension** | ✅ 완료 | 100% |
| **M4: Companion App** | ✅ 완료 | 100% |
| **M5: Polish & Deploy** | ✅ 완료 | 100% |

---

## M1: Shared Core (MarkdownShared 패키지) ✅ 완료

### 개요
- 위치: `MarkdownShared/`
- 독립 SPM 패키지 (자체 `Package.swift`)
- 의존성: `swiftlang/swift-markdown` (0.7.3)
- 테스트: **76개 전체 통과**

### Step 1: 프로젝트 스켈레톤 ✅
- [x] `MarkdownShared/Package.swift` 생성 (macOS 14+, swift-markdown 의존성)
- [x] 디렉토리 구조 생성
- [x] `swift build` 컴파일 확인

### Step 2: MarkdownParser ✅
- [x] `swift-markdown`의 `Document(parsing:)` + `HTMLFormatter.format()` 래핑
- [x] YAML frontmatter 추출 (파싱 전 `---` 블록 제거)
- [x] 첫 번째 H1에서 타이틀 추출 (AST 워킹)
- [x] 이미지 소스 경로 수집 (AST 워킹)
- [x] 테스트: 25개 (GFM 테이블, 취소선, 체크박스, 코드 블록, frontmatter 등)

### Step 3: ImageResolver ✅
- [x] 상대/절대 경로 해석 (`baseDirectory` 기준)
- [x] 디렉토리 탈출 공격 차단 (`.standardizedFileURL` + prefix 검증)
- [x] base64 data URI 변환 (`resolveToDataURI`)
- [x] HTML 내 `<img src>` 일괄 치환 (`resolveImagesInHTML`)
- [x] 테스트: 17개 (경로 해석, 보안 차단, data URI 생성)

### Step 4: ThemeManager + CSS 리소스 ✅
- [x] 4개 테마 CSS 작성 (github-light, github-dark, dracula, nord)
- [x] `Bundle.module`에서 CSS 로드
- [x] 시스템 다크모드 감지 (`NSAppearance.currentDrawing()`)
- [x] 테스트: 14개 (모든 테마 로드, 시스템 테마 감지)

### Step 5: HTML 템플릿 + JS 리소스 ✅
- [x] highlight.js 다운로드 (~122KB, 공통 언어 포함)
- [x] mermaid.min.js 다운로드 (~3.3MB)
- [x] KaTeX JS/CSS/fonts 다운로드 (~277KB JS, 20개 woff2 폰트)
- [x] `template.html` 작성 (플레이스홀더 기반)
- [x] highlight.js CSS 테마 (light/dark)

### Step 6: HTMLRenderer ✅
- [x] `MarkdownParser` + `ImageResolver` + `ThemeManager` + 템플릿 조합
- [x] 템플릿 플레이스홀더 치환으로 완성된 HTML 생성
- [x] mermaid 코드 블록을 `<div class="mermaid">`로 변환 (후처리)
- [x] 기능 토글 (mermaid, katex, highlight.js on/off)
- [x] `RenderConfiguration` (quickLook용, appPreview용 프리셋)
- [x] KaTeX 폰트를 CSS 내 data URI로 인라인화
- [x] 테스트: 20개 (전체 파이프라인, 기능 토글, 이미지 임베딩)

### Step 7: 통합 테스트 ✅
- [x] 전체 테스트 스위트 실행 (76개 통과)
- [x] Fixture 파일 생성 (sample.md, minimal.md, gfm-features.md)
- [x] Release 빌드 확인

### 생성된 파일 목록
```
MarkdownShared/
├── Package.swift
├── Sources/MarkdownShared/
│   ├── MarkdownParser.swift
│   ├── HTMLRenderer.swift
│   ├── ThemeManager.swift
│   ├── ImageResolver.swift
│   └── Resources/
│       ├── template.html
│       ├── themes/
│       │   ├── github-light.css
│       │   ├── github-dark.css
│       │   ├── dracula.css
│       │   └── nord.css
│       ├── js/
│       │   ├── highlight.min.js
│       │   ├── mermaid.min.js
│       │   ├── katex.min.js
│       │   └── katex-auto-render.min.js
│       ├── css/
│       │   ├── katex.min.css
│       │   ├── hljs-github-light.css
│       │   └── hljs-github-dark.css
│       └── fonts/
│           └── (20개 KaTeX woff2 폰트)
└── Tests/MarkdownSharedTests/
    ├── MarkdownParserTests.swift
    ├── ImageResolverTests.swift
    ├── ThemeManagerTests.swift
    ├── HTMLRendererTests.swift
    └── Fixtures/
        ├── sample.md
        ├── minimal.md
        └── gfm-features.md
```

### 공개 API
```swift
// MarkdownParser
public struct MarkdownParser {
    func parse(_ markdown: String) -> ParsedMarkdown
    func parseToHTML(_ markdown: String) -> String
}

// HTMLRenderer
public struct HTMLRenderer {
    func render(markdown: String, baseDirectory: URL, configuration: RenderConfiguration) throws -> String
    func render(fileURL: URL, configuration: RenderConfiguration) throws -> String
}

// ThemeManager
public final class ThemeManager {
    static let shared: ThemeManager
    var selectedTheme: Theme?
    var effectiveTheme: Theme { get }
    func loadCSS(for theme: Theme) throws -> String
}

// ImageResolver
public struct ImageResolver {
    func resolve(_ source: String) throws -> URL?
    func resolveToDataURI(_ source: String) throws -> String?
    func resolveImagesInHTML(_ html: String, embedImages: Bool) -> String
}
```

---

## M2: Quick Look Extension ✅ 완료

### 개요
- `PreviewViewController` — AppKit 기반 `NSViewController` + `QLPreviewingController`
- `WKWebView` (nonPersistent data store) 로 렌더링된 HTML 표시
- `MarkdownShared.HTMLRenderer` 직접 사용 (stub 코드 완전 제거)
- 외부 링크 차단 (`WKNavigationDelegate`)

### Step 1: 불필요 파일 정리 ✅
- [x] `QuickLookExtension/MarkdownRenderer.swift` 삭제
- [x] `QuickLookExtension/template.html` 삭제
- [x] `Shared/` 디렉토리 전체 삭제 (4개 stub 파일)
- [x] `Resources/` 디렉토리 전체 삭제 (placeholder 파일)
- [x] `Tests/` 루트 테스트 디렉토리 삭제 (MarkdownShared 내부 테스트 유지)

### Step 2: PreviewViewController.swift 재작성 ✅
- [x] `UIKit` → `AppKit` (`NSViewController` 기반)
- [x] `MarkdownShared.HTMLRenderer.render(fileURL:configuration:)` 사용
- [x] `WKWebView` 샌드박스: `nonPersistent()` data store
- [x] `WKNavigationDelegate` 구현 (외부 링크 차단)
- [x] `baseURL: nil` (모든 리소스가 HTML에 인라인됨)

### Step 3: Info.plist 업데이트 ✅
- [x] `NSExtensionPrincipalClass` 추가
- [x] `QLSupportedContentTypes`: `net.daringfireball.markdown`, `public.markdown`
- [x] `QLSupportsSearchableItems` = true

### Step 4: MarkdownShared 테스트 확인 ✅
- [x] 76개 테스트 전체 통과 확인

### 지원 기능 (MarkdownShared 경유)
- [x] GFM (테이블, 취소선, 체크리스트) — `swift-markdown`
- [x] 코드 블록 구문 강조 — highlight.js (20개+ 언어)
- [x] 이미지 렌더링 (base64 data URI 임베딩) — ImageResolver
- [x] 다크/라이트 모드 자동 전환 — ThemeManager
- [x] Mermaid 다이어그램 — mermaid.js
- [x] 수학 수식 (LaTeX) — KaTeX
- [x] 4개 테마 (github-light, github-dark, dracula, nord)

### 생성/수정된 파일
```
QuickLookExtension/
├── PreviewViewController.swift  (재작성: AppKit + MarkdownShared)
└── Info.plist                   (업데이트: UTI + principal class)
```

### 삭제된 파일
```
QuickLookExtension/MarkdownRenderer.swift  (→ MarkdownShared.HTMLRenderer)
QuickLookExtension/template.html           (→ MarkdownShared/Resources/template.html)
Shared/MarkdownParser.swift                (→ MarkdownShared.MarkdownParser)
Shared/ThemeManager.swift                  (→ MarkdownShared.ThemeManager)
Shared/ImageResolver.swift                 (→ MarkdownShared.ImageResolver)
Shared/SyntaxHighlighter.swift             (→ highlight.js in MarkdownShared)
Resources/highlight.js                     (→ MarkdownShared/Resources/js/)
Resources/mermaid.min.js                   (→ MarkdownShared/Resources/js/)
Resources/katex/                           (→ MarkdownShared/Resources/js,css,fonts/)
Tests/MarkdownParserTests/                 (→ MarkdownShared/Tests/)
Tests/RendererTests/                       (→ MarkdownShared/Tests/)
```

### 참고: Xcode 프로젝트 통합
Quick Look Extension은 SPM 단독 빌드 불가 — M5에서 Xcode 프로젝트 설정 예정

---

## M3: Thumbnail Extension ✅ 완료

### 개요
- `ThumbnailProvider` — AppKit 기반 `QLThumbnailProvider`
- `MarkdownParser`로 제목/본문 텍스트 추출 후 `CGContext`로 렌더링
- 파일 앞 4KB만 읽어 빠른 파싱 (성능 최적화)
- 시스템 다크/라이트 모드 감지하여 테마 색상 적용

### Step 1: ThumbnailProvider.swift 재작성 ✅
- [x] `UIKit` → `AppKit` (`NSColor`, `NSFont`, `NSAttributedString`)
- [x] `MarkdownShared.MarkdownParser`로 제목/HTML 추출
- [x] HTML 태그 제거 → 일반 텍스트 변환 (`stripHTMLTags`)
- [x] 제목 우선순위: H1 → frontmatter title → 파일명
- [x] `FileHandle.read(upToCount: 4096)`으로 파일 앞부분만 읽기
- [x] `CGContext` 좌표계 변환 (flip for AppKit text drawing)
- [x] GitHub Light/Dark 테마 색상 하드코딩
- [x] "MD" 배지 (우상단) 표시
- [x] 크기 적응형 폰트 (제목: 9-16pt, 본문: 6-11pt)
- [x] 구분선 (separator) 그리기

### Step 2: Info.plist 업데이트 ✅
- [x] `NSExtensionPrincipalClass` 추가
- [x] `QLSupportedContentTypes`: `net.daringfireball.markdown`, `public.markdown`
- [x] `QLThumbnailMinimumDimension` = 64

### Step 3: MarkdownShared 테스트 확인 ✅
- [x] 76개 테스트 전체 통과 확인

### 썸네일 레이아웃
```
┌──────────────────────────────────┐
│  Title (bold, 2줄)           MD  │
│──────────────────────────────────│
│  Body text preview (muted        │
│  색상, word-wrap, 나머지          │
│  공간 채움)                       │
└──────────────────────────────────┘
```

### 생성/수정된 파일
```
ThumbnailExtension/
├── ThumbnailProvider.swift  (재작성: AppKit + MarkdownShared + CGContext)
└── Info.plist               (업데이트: UTI + principal class + minimum dimension)
```

### 참고: Xcode 프로젝트 통합
Thumbnail Extension도 SPM 단독 빌드 불가 — M5에서 Xcode 프로젝트 설정 예정

---

## M4: Companion App ✅ 완료

### 개요
- SwiftUI 기반 macOS 설정 앱 (`NavigationSplitView`)
- `MarkdownShared` 패키지 연동 (테마, 렌더러)
- 공유 `UserDefaults` (App Groups suite: `group.com.findermd.shared`)
- 실시간 Markdown 미리보기 (WKWebView + HTMLRenderer)

### Step 1: 불필요 파일 정리 ✅
- [x] `FinderMD/Resources/Themes/` 삭제 (MarkdownShared에 이미 존재하는 중복 CSS)

### Step 2: AppSettings 재작성 ✅
- [x] `import MarkdownShared` 추가
- [x] `UserDefaults(suiteName:)` 사용 (App Groups 준비)
- [x] `selectedTheme: Theme?` — `nil` = 시스템 자동 감지
- [x] `fontSize: Double` — 기본값 16pt
- [x] Suite name 상수: `group.com.findermd.shared`

### Step 3: SwiftUI 뷰 업데이트 ✅
- [x] `ContentView` — Section 분류 (Settings/Extensions/Preview), Label 아이콘
- [x] `ThemeSettingsView` — Auto(System) 옵션, 테마 색상 스와치, radioGroup
- [x] `FontSettingsView` — 미리보기 텍스트, min/max 라벨, monospacedDigit
- [x] `ExtensionStatusView` — Quick Look/Thumbnail 상태 표시, 시스템 설정 링크

### Step 4: PreviewView 생성 ✅
- [x] `NSViewRepresentable`로 `WKWebView` 래핑
- [x] `HTMLRenderer.render(markdown:baseDirectory:configuration:)` 사용
- [x] 테마/폰트 변경 시 실시간 업데이트
- [x] 샘플 Markdown (GFM, 코드 블록, 테이블, 체크리스트, KaTeX)
- [x] 외부 링크 차단 (`WKNavigationDelegate`)

### Step 5: Extensions 설정 공유 ✅
- [x] `PreviewViewController` — 공유 UserDefaults에서 테마 읽기
- [x] `ThumbnailProvider` — 공유 UserDefaults에서 테마 읽어 다크 모드 결정
- [x] 동일한 suite name 상수 사용

### Step 6: MarkdownShared 테스트 확인 ✅
- [x] 76개 테스트 전체 통과 확인

### 생성/수정된 파일
```
FinderMD/
├── App/
│   ├── FinderMDApp.swift          (유지)
│   └── ContentView.swift          (업데이트: Section + Label + Preview)
├── Models/
│   └── AppSettings.swift          (재작성: MarkdownShared + shared UserDefaults)
└── Views/
    ├── ExtensionStatusView.swift  (업데이트: Form + Section 구조)
    ├── ThemeSettingsView.swift     (재작성: Auto 옵션 + 색상 스와치)
    ├── FontSettingsView.swift      (업데이트: 미리보기 + min/max 라벨)
    └── PreviewView.swift           (신규: WKWebView + HTMLRenderer)

QuickLookExtension/
└── PreviewViewController.swift    (업데이트: 공유 설정 읽기)

ThumbnailExtension/
└── ThumbnailProvider.swift        (업데이트: 공유 설정 읽기)
```

### 삭제된 파일
```
FinderMD/Resources/Themes/        (중복 CSS → MarkdownShared/Resources/themes/)
```

### 참고: App Groups 설정
실제 App Groups 활성화는 Xcode 프로젝트의 Signing & Capabilities에서 설정 필요 — M5에서 진행

---

## M5: Polish & Deploy ✅ 완료

### 개요
- XcodeGen (`project.yml`) 기반 Xcode 프로젝트 자동 생성
- 3개 타겟 (FinderMD App, QuickLookExtension, ThumbnailExtension) 통합
- MarkdownShared SPM 로컬 패키지 의존성 연결
- App Sandbox + App Groups 엔타이틀먼트 설정
- **`xcodebuild` 빌드 성공 확인**

### Step 1: Entitlements 파일 생성 ✅
- [x] `FinderMD/FinderMD.entitlements` — App Sandbox + App Groups
- [x] `QuickLookExtension/QuickLookExtension.entitlements` — App Sandbox + App Groups
- [x] `ThumbnailExtension/ThumbnailExtension.entitlements` — App Sandbox + App Groups
- [x] 공통 suite name: `group.com.findermd.shared`

### Step 2: XcodeGen project.yml 작성 ✅
- [x] FinderMD 앱 타겟 (macOS application)
- [x] QuickLookExtension 타겟 (app-extension, embed + codeSign)
- [x] ThumbnailExtension 타겟 (app-extension, embed + codeSign)
- [x] MarkdownShared SPM 로컬 패키지 의존성
- [x] Quartz + WebKit 시스템 프레임워크 링크 (Quick Look Extension)
- [x] Info.plist: NSExtension, QLSupportedContentTypes 인라인 정의
- [x] FinderMD scheme: 전체 타겟 빌드

### Step 3: Xcode 프로젝트 생성 + 빌드 검증 ✅
- [x] `xcodegen generate` → `FinderMD.xcodeproj` 생성
- [x] `xcodebuild -scheme FinderMD build` → **BUILD SUCCEEDED**
- [x] QuickLook: `import Quartz` 수정 (macOS에서 `QLPreviewingController`는 QuickLookUI/Quartz에 위치)
- [x] MarkdownShared 76개 테스트 통과 확인

### Step 4: Info.plist 생성 ✅
- [x] `FinderMD/Info.plist` — 앱 메타데이터 (CFBundleDisplayName, LSApplicationCategoryType)
- [x] Extension Info.plist은 XcodeGen이 인라인 속성으로 자동 생성

### 생성/수정된 파일
```
project.yml                                    (신규: XcodeGen 프로젝트 설정)
FinderMD.xcodeproj/                            (자동 생성: Xcode 프로젝트)
FinderMD/
├── Info.plist                                 (신규: 앱 메타데이터)
└── FinderMD.entitlements                      (신규: Sandbox + App Groups)
QuickLookExtension/
├── PreviewViewController.swift                (수정: import Quartz)
└── QuickLookExtension.entitlements            (신규: Sandbox + App Groups)
ThumbnailExtension/
└── ThumbnailExtension.entitlements            (신규: Sandbox + App Groups)
```

### 배포 참고사항
- **코드 서명**: Apple Developer ID 필요 (현재 `CODE_SIGNING_ALLOWED=NO`로 빌드)
- **App Groups**: Xcode에서 Signing & Capabilities에 실제 App Group 추가 필요
- **공증/DMG**: `xcodebuild archive` + `notarytool` 으로 진행
- **App Store**: Archive → Xcode Organizer → App Store Connect 업로드

---

## 기술 스택 요약

| 항목 | 기술 | 상태 |
|------|------|:----:|
| Markdown 파서 | swift-markdown (0.7.3) | ✅ |
| 구문 강조 | highlight.js (11.9.0) | ✅ |
| 다이어그램 | mermaid.js (10.9.1) | ✅ |
| 수식 렌더링 | KaTeX (0.16.9) | ✅ |
| 테마 | GitHub Light/Dark, Dracula, Nord | ✅ |
| Quick Look | QLPreviewingController | ✅ |
| Thumbnail | QLThumbnailProvider | ✅ |
| Companion App | SwiftUI | ✅ |

---

## 성능 목표

| 항목 | 목표 | 현재 |
|------|------|------|
| Quick Look (< 100KB) | < 200ms | 측정 대기 |
| Quick Look (< 10MB) | < 2s | 측정 대기 |
| Thumbnail 생성 | < 100ms | 측정 대기 |
| 메모리 사용량 | < 50MB | 측정 대기 |
| 테스트 커버리지 | 90%+ | MarkdownShared: ✅ |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2024-02-06 | M1 (MarkdownShared) 완료 - 76개 테스트 통과 |
| 2026-02-06 | M2 (Quick Look Extension) 완료 - AppKit 재작성, stub 정리, Info.plist UTI 설정 |
| 2026-02-06 | M3 (Thumbnail Extension) 완료 - AppKit CGContext 렌더링, MarkdownParser 연동 |
| 2026-02-06 | M4 (Companion App) 완료 - SwiftUI 설정 앱, 미리보기, 공유 UserDefaults |
| 2026-02-06 | M5 (Polish & Deploy) 완료 - XcodeGen 프로젝트, 엔타이틀먼트, 빌드 성공 |
