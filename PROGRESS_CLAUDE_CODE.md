# Finder MD - Claude Code 작업 진행 현황

> 브랜치: `agent/claude-code`
> 최종 업데이트: 2024-02-06

---

## 전체 마일스톤 현황

| 마일스톤 | 상태 | 완료율 |
|---------|:----:|:------:|
| **M1: Shared Core** | ✅ 완료 | 100% |
| **M2: Quick Look Extension** | ⏳ 대기 | 0% |
| **M3: Thumbnail Extension** | ⏳ 대기 | 0% |
| **M4: Companion App** | ⏳ 대기 | 0% |
| **M5: Polish & Deploy** | ⏳ 대기 | 0% |

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

## M2: Quick Look Extension ⏳ 대기

### PRD 요구사항 (P0 필수)
- [ ] Finder에서 `.md` 파일 선택 후 스페이스바로 렌더링된 Markdown 미리보기
- [ ] GFM (GitHub Flavored Markdown) 완전 지원
- [ ] 코드 블록 구문 강조 (20개 이상 언어)
- [ ] 이미지 렌더링 (로컬 상대/절대 경로)
- [ ] 다크모드 / 라이트모드 자동 전환
- [ ] Mermaid 다이어그램 렌더링

### PRD 요구사항 (P1 중요)
- [ ] 수학 수식 렌더링 (LaTeX / KaTeX)
- [ ] Frontmatter (YAML) 메타데이터 표시
- [ ] 목차(TOC) 자동 생성 및 사이드바 표시
- [ ] 파일 내 앵커 링크 동작
- [ ] 큰 파일 성능 최적화 (10MB 이상)

### 구현 계획
1. [ ] `QLPreviewingController` 서브클래스 구현
2. [ ] `WKWebView` 설정 및 샌드박스 대응
3. [ ] `MarkdownShared` 패키지 연동
4. [ ] `Info.plist` 설정 (지원 UTI: `net.daringfireball.markdown`)
5. [ ] 에러 핸들링 및 로딩 인디케이터
6. [ ] 성능 테스트 (< 200ms @ 100KB, < 2s @ 10MB)

---

## M3: Thumbnail Extension ⏳ 대기

### PRD 요구사항 (P0 필수)
- [ ] Finder에서 `.md` 파일 아이콘에 렌더링된 내용 축소 미리보기
- [ ] 첫 몇 줄(제목 + 본문 시작)을 시각적으로 표시
- [ ] 아이콘 크기별 적응형 렌더링

### PRD 요구사항 (P1 중요)
- [ ] 파일에 이미지가 포함된 경우 대표 이미지 썸네일 사용

### 구현 계획
1. [ ] `QLThumbnailProvider` 서브클래스 구현
2. [ ] `MarkdownParser`로 제목/본문 추출
3. [ ] `CGContext`로 텍스트 렌더링
4. [ ] 대표 이미지 추출 및 썸네일 생성
5. [ ] 크기별 레이아웃 적응
6. [ ] 성능 테스트 (< 100ms)

---

## M4: Companion App ⏳ 대기

### PRD 요구사항 (P0 필수)
- [ ] 확장 프로그램 활성화/비활성화 상태 표시 및 시스템 설정 연결
- [ ] 테마 선택 (GitHub Light, GitHub Dark, Dracula, Nord)
- [ ] 폰트 크기 조절

### PRD 요구사항 (P1 중요)
- [ ] 커스텀 CSS 편집기
- [ ] 지원 확장자 관리
- [ ] 코드 블록 테마 선택

### PRD 요구사항 (P2 부가)
- [ ] 렌더링 미리보기 (설정 변경 실시간 반영)
- [ ] Markdown 테스트 파일로 즉시 확인

### 구현 계획
1. [ ] SwiftUI 앱 구조 설정
2. [ ] `AppSettings` 모델 (UserDefaults 연동)
3. [ ] `ExtensionStatusView` - 시스템 설정 연결
4. [ ] `ThemeSettingsView` - 테마 선택 UI
5. [ ] `FontSettingsView` - 폰트 크기 슬라이더
6. [ ] 설정값을 Extensions와 공유 (App Groups)
7. [ ] 미리보기 기능 (WKWebView + MarkdownShared)

---

## M5: Polish & Deploy ⏳ 대기

### 통합
- [ ] 모든 컴포넌트 Xcode 프로젝트 통합
- [ ] App Groups 설정 (설정 공유)
- [ ] 코드 서명 설정

### 성능 최적화
- [ ] Quick Look 표시 시간 < 200ms (100KB 미만)
- [ ] Quick Look 표시 시간 < 2s (10MB 미만)
- [ ] Thumbnail 생성 시간 < 100ms
- [ ] 메모리 사용량 < 50MB

### 테스트
- [ ] 통합 테스트
- [ ] 다양한 Markdown 파일 검증
- [ ] GitHub 렌더링 대비 95% 일치 확인

### 배포 준비
- [ ] App Store 제출 준비
- [ ] GitHub Releases용 공증 DMG 생성
- [ ] README.md 작성

---

## 기술 스택 요약

| 항목 | 기술 | 상태 |
|------|------|:----:|
| Markdown 파서 | swift-markdown (0.7.3) | ✅ |
| 구문 강조 | highlight.js (11.9.0) | ✅ |
| 다이어그램 | mermaid.js (10.9.1) | ✅ |
| 수식 렌더링 | KaTeX (0.16.9) | ✅ |
| 테마 | GitHub Light/Dark, Dracula, Nord | ✅ |
| Quick Look | QLPreviewingController | ⏳ |
| Thumbnail | QLThumbnailProvider | ⏳ |
| Companion App | SwiftUI | ⏳ |

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
