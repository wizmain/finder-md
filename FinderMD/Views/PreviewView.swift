import SwiftUI
import WebKit
import MarkdownShared

struct PreviewView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        MarkdownWebView(
            theme: settings.selectedTheme,
            fontSize: settings.fontSize
        )
        .navigationTitle("Preview")
    }
}

// MARK: - NSViewRepresentable

private struct MarkdownWebView: NSViewRepresentable {
    let theme: Theme?
    let fontSize: Double

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        loadPreview(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        loadPreview(into: webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func loadPreview(into webView: WKWebView) {
        let renderer = HTMLRenderer()
        var config = RenderConfiguration.appPreview
        config.theme = theme
        let tempDir = FileManager.default.temporaryDirectory

        do {
            let html = try renderer.render(
                markdown: Self.sampleMarkdown,
                baseDirectory: tempDir,
                configuration: config
            )
            webView.loadHTMLString(html, baseURL: nil)
        } catch {
            webView.loadHTMLString("<pre>Error: \(error.localizedDescription)</pre>", baseURL: nil)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }

    private static let sampleMarkdown = """
    # Finder MD Preview

    This is a **live preview** of how your Markdown files will look in Quick Look.

    ## Features

    - **Bold**, *italic*, and ~~strikethrough~~ text
    - [Links](https://example.com) are rendered but blocked in Quick Look
    - GFM tables, task lists, and more

    ### Code Block

    ```swift
    let renderer = HTMLRenderer()
    let html = try renderer.render(fileURL: url)
    ```

    ### Task List

    - [x] MarkdownShared package
    - [x] Quick Look extension
    - [x] Thumbnail extension
    - [x] Companion app
    - [ ] Polish & deploy

    ### Table

    | Feature | Status |
    |---------|--------|
    | Syntax highlighting | Supported |
    | Mermaid diagrams | Supported |
    | KaTeX math | Supported |
    | Dark mode | Auto-detect |

    > Markdown is rendered using the same engine as the Quick Look extension.

    ### Math (KaTeX)

    The quadratic formula: $x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$
    """
}
