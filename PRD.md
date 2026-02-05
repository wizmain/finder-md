# PRD: Finder MD — macOS Finder 통합 Markdown Viewer

## 1. 개요

### 1.1 제품 비전
macOS Finder의 미리보기(Quick Look)와 네이티브하게 통합되어, 별도 앱 실행 없이 Markdown 파일을 렌더링된 상태로 즉시 확인할 수 있는 시스템 확장 프로그램.

### 1.2 문제 정의
| 현재 상황 | 문제 |
|-----------|------|
| Finder에서 `.md` 파일 스페이스바 미리보기 | 원시 텍스트(raw text)로만 표시됨 |
| Markdown 내용 확인 | 별도 에디터(VSCode, Typora 등)를 실행해야 함 |
| GitHub README 등 확인 | 브라우저를 열어야 함 |

### 1.3 목표 사용자
- macOS를 사용하는 개발자
- 기술 문서를 자주 다루는 엔지니어/PM
- Markdown 기반 노트를 사용하는 일반 사용자 (Obsidian, Logseq 등)

---

## 2. 제품 구성

### 2.1 전체 아키텍처

```
┌─────────────────────────────────────────────┐
│                Finder MD                     │
├──────────┬──────────────┬───────────────────┤
│ Quick    │ Thumbnail    │ Companion App     │
│ Look     │ Extension    │ (설정 & 관리)      │
│ Extension│              │                   │
├──────────┴──────────────┴───────────────────┤
│          Markdown Rendering Engine           │
│          (cmark-gfm / Swift)                 │
└─────────────────────────────────────────────┘
```

### 2.2 컴포넌트 정의

| 컴포넌트 | 유형 | 설명 |
|----------|------|------|
| **Quick Look Extension** | QLPreviewingController | 스페이스바 미리보기에서 렌더링된 Markdown 표시 |
| **Thumbnail Extension** | QLThumbnailProvider | Finder 아이콘에 Markdown 내용 미리보기 썸네일 표시 |
| **Companion App** | SwiftUI App | 테마 설정, 확장 관리, 라이선스 등 |

---

## 3. 기능 요구사항

### 3.1 Quick Look Extension (핵심 기능)

#### P0 — 필수
- [ ] Finder에서 `.md` 파일 선택 후 스페이스바로 렌더링된 Markdown 미리보기
- [ ] GFM (GitHub Flavored Markdown) 완전 지원
  - 테이블, 체크박스, 취소선, 자동 링크
- [ ] 코드 블록 구문 강조 (Syntax Highlighting)
  - 최소 20개 이상 언어 지원 (Swift, Python, JS, TS, Go, Rust 등)
- [ ] 이미지 렌더링
  - 로컬 상대경로 이미지 (`./images/photo.png`)
  - 로컬 절대경로 이미지
- [ ] 다크모드 / 라이트모드 자동 전환 (시스템 설정 연동)
- [ ] Mermaid 다이어그램 렌더링

#### P1 — 중요
- [ ] 수학 수식 렌더링 (LaTeX / KaTeX)
- [ ] Frontmatter (YAML) 메타데이터 표시
- [ ] 목차(TOC) 자동 생성 및 사이드바 표시
- [ ] 파일 내 앵커 링크 동작
- [ ] 큰 파일 성능 최적화 (10MB 이상)

#### P2 — 부가
- [ ] 원본 Markdown ↔ 렌더링 토글 뷰
- [ ] 외부 URL 이미지 렌더링 (네트워크 권한 필요)
- [ ] `.mdx`, `.markdown`, `.mdown` 확장자 지원
- [ ] 커스텀 CSS 테마 적용

### 3.2 Thumbnail Extension

#### P0 — 필수
- [ ] Finder에서 `.md` 파일 아이콘에 렌더링된 내용 축소 미리보기
- [ ] 첫 몇 줄(제목 + 본문 시작)을 시각적으로 표시
- [ ] 아이콘 크기별 적응형 렌더링

#### P1 — 중요
- [ ] 파일에 이미지가 포함된 경우 대표 이미지 썸네일 사용

### 3.3 Companion App (설정 앱)

#### P0 — 필수
- [ ] 확장 프로그램 활성화/비활성화 상태 표시 및 시스템 설정 연결
- [ ] 테마 선택 (GitHub Light, GitHub Dark, Dracula, Nord 등)
- [ ] 폰트 크기 조절

#### P1 — 중요
- [ ] 커스텀 CSS 편집기
- [ ] 지원 확장자 관리
- [ ] 코드 블록 테마 선택

#### P2 — 부가
- [ ] 렌더링 미리보기 (설정 변경 실시간 반영)
- [ ] Markdown 테스트 파일로 즉시 확인

---

## 4. 기술 사양

### 4.1 기술 스택

| 항목 | 기술 | 이유 |
|------|------|------|
| 언어 | **Swift** | macOS 네이티브 확장 필수 |
| UI 프레임워크 | **SwiftUI** | Companion App용 |
| Markdown 파서 | **cmark-gfm** (Swift 래퍼) | GitHub 호환 + 고성능 C 기반 |
| 구문 강조 | **Splash** 또는 **Highlightr** | Swift 네이티브 |
| 수식 렌더링 | **KaTeX** (WKWebView 내) | 경량 + 빠른 렌더링 |
| 다이어그램 | **Mermaid.js** (WKWebView 내) | 업계 표준 |
| Quick Look | **QLPreviewingController** | macOS Quick Look API |
| Thumbnail | **QLThumbnailProvider** | macOS Thumbnail API |
| 빌드 | **Xcode + SPM** | Apple 생태계 표준 |

### 4.2 렌더링 전략

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  .md 파일     │────▶│  cmark-gfm   │────▶│   HTML 변환   │
│  (원본 텍스트) │     │  (파싱)       │     │              │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                          ┌───────▼───────┐
                                          │  WKWebView     │
                                          │  + CSS 테마     │
                                          │  + Syntax HL   │
                                          │  + KaTeX       │
                                          │  + Mermaid     │
                                          └───────────────┘
```

### 4.3 성능 요구사항

| 항목 | 목표 |
|------|------|
| Quick Look 표시 시간 (일반 파일 < 100KB) | < 200ms |
| Quick Look 표시 시간 (대용량 < 10MB) | < 2초 |
| Thumbnail 생성 시간 | < 100ms |
| 메모리 사용량 | < 50MB |

### 4.4 보안 고려사항

- Quick Look Extension은 **샌드박스** 환경에서 실행
- 외부 네트워크 접근은 기본 비활성화 (설정에서 활성화 가능)
- 로컬 이미지는 파일 상대경로만 허용 (디렉토리 탈출 방지)
- JavaScript 실행은 Mermaid/KaTeX 렌더링에만 제한적 허용

---

## 5. 프로젝트 구조

```
finder-md/
├── FinderMD/                      # Companion App (SwiftUI)
│   ├── App/
│   │   ├── FinderMDApp.swift
│   │   └── ContentView.swift
│   ├── Views/
│   │   ├── ThemeSettingsView.swift
│   │   ├── FontSettingsView.swift
│   │   └── ExtensionStatusView.swift
│   ├── Models/
│   │   └── AppSettings.swift
│   └── Resources/
│       └── Themes/
│           ├── github-light.css
│           ├── github-dark.css
│           └── dracula.css
│
├── QuickLookExtension/            # Quick Look 미리보기
│   ├── PreviewViewController.swift
│   ├── MarkdownRenderer.swift
│   ├── Info.plist
│   └── template.html
│
├── ThumbnailExtension/            # Thumbnail 생성
│   ├── ThumbnailProvider.swift
│   └── Info.plist
│
├── Shared/                        # 공유 모듈
│   ├── MarkdownParser.swift       # cmark-gfm 래퍼
│   ├── SyntaxHighlighter.swift
│   ├── ImageResolver.swift        # 로컬 이미지 경로 처리
│   └── ThemeManager.swift
│
├── Resources/
│   ├── highlight.js               # 번들된 구문 강조
│   ├── mermaid.min.js             # 번들된 Mermaid
│   └── katex/                     # 번들된 KaTeX
│
├── Tests/
│   ├── MarkdownParserTests/
│   ├── RendererTests/
│   └── Fixtures/                  # 테스트용 .md 파일
│
├── PRD.md
└── README.md
```

---

## 6. 에이전트 작업 분배 (병렬 개발)

worktree 기반으로 에이전트별 독립 작업:

| 에이전트 | 브랜치 | 담당 영역 | 의존성 |
|---------|--------|----------|--------|
| **Agent A** | `agent/shared-core` | `Shared/` — 파서, 렌더러, 테마 매니저 | 없음 (최우선) |
| **Agent B** | `agent/quicklook-ext` | `QuickLookExtension/` | Shared 완료 후 |
| **Agent C** | `agent/thumbnail-ext` | `ThumbnailExtension/` | Shared 완료 후 |
| **Agent D** | `agent/companion-app` | `FinderMD/` — 설정 앱 UI | Shared 완료 후 |
| **Agent E** | `agent/resources` | `Resources/` — CSS 테마, JS 번들링 | 없음 (독립) |

### 작업 흐름

```
Phase 1 (병렬)
  Agent A → Shared Core (파서 + 렌더러)
  Agent E → Resources (CSS 테마 + JS 번들)

Phase 2 (병렬, Phase 1 완료 후)
  Agent B → Quick Look Extension
  Agent C → Thumbnail Extension
  Agent D → Companion App

Phase 3 (통합)
  main에 순차 머지 → 통합 테스트
```

---

## 7. 배포

| 항목 | 상세 |
|------|------|
| 최소 지원 OS | macOS 14.0 (Sonoma) |
| 배포 방식 | Mac App Store + GitHub Releases (공증된 DMG) |
| 서명 | Apple Developer ID 필수 |
| 라이선스 | MIT (오픈소스) |

---

## 8. 성공 지표

| 지표 | 목표 |
|------|------|
| Quick Look 렌더링 정확도 | GitHub 렌더링 대비 95% 이상 일치 |
| 지원 GFM 기능 커버리지 | 100% |
| 앱 크래시율 | < 0.1% |
| 사용자 설치 후 확장 활성화 성공률 | > 95% |

---

## 9. 경쟁 제품 분석

| 제품 | Quick Look | Thumbnail | GFM | 코드 강조 | Mermaid | 무료 |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| **Finder MD (본 프로젝트)** | O | O | O | O | O | O |
| QLMarkdown | O | X | 부분 | O | X | O |
| Peek | O | X | 부분 | 부분 | X | X |
| Marked 2 | X (별도 앱) | X | O | O | X | X |

---

## 10. 마일스톤

| 마일스톤 | 산출물 | 완료 기준 |
|---------|--------|----------|
| **M1: Core** | Shared 모듈 완성 | GFM 파싱 + HTML 렌더링 + 테스트 통과 |
| **M2: Quick Look** | Quick Look 확장 동작 | Finder 스페이스바로 렌더링된 Markdown 표시 |
| **M3: Thumbnail** | Thumbnail 확장 동작 | Finder에서 .md 파일 아이콘 미리보기 표시 |
| **M4: App** | Companion App 완성 | 테마/폰트 설정 변경 가능 |
| **M5: Polish** | 최종 통합 | 성능 최적화 + 버그 수정 + 배포 준비 |
