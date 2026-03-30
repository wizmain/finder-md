import Foundation

/// Configuration for HTML rendering.
public struct RenderConfiguration: Sendable {
    public var theme: Theme?
    public var embedImages: Bool
    public var enableHighlightJS: Bool
    public var enableMermaid: Bool
    public var enableKaTeX: Bool

    public init(
        theme: Theme? = nil,
        embedImages: Bool = true,
        enableHighlightJS: Bool = true,
        enableMermaid: Bool = true,
        enableKaTeX: Bool = true
    ) {
        self.theme = theme
        self.embedImages = embedImages
        self.enableHighlightJS = enableHighlightJS
        self.enableMermaid = enableMermaid
        self.enableKaTeX = enableKaTeX
    }

    /// Preset for Quick Look rendering (all features, images embedded).
    public static let quickLook = RenderConfiguration(
        embedImages: true,
        enableHighlightJS: true,
        enableMermaid: true,
        enableKaTeX: true
    )

    /// Preset for app preview (no image embedding needed).
    public static let appPreview = RenderConfiguration(
        embedImages: false,
        enableHighlightJS: true,
        enableMermaid: true,
        enableKaTeX: true
    )

    /// Preset for HWPX document rendering (no code/math features needed).
    public static let hwpxPreview = RenderConfiguration(
        embedImages: true,
        enableHighlightJS: false,
        enableMermaid: false,
        enableKaTeX: false
    )
}

/// Errors that can occur during HTML rendering.
public enum RenderError: Error, LocalizedError {
    case templateNotFound
    case resourceNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "HTML template file not found in bundle"
        case .resourceNotFound(let name):
            return "Resource not found in bundle: \(name)"
        }
    }
}

/// Composes a complete self-contained HTML document from Markdown source.
public struct HTMLRenderer {

    private let parser = MarkdownParser()
    private let themeManager = ThemeManager.shared

    public init() {}

    // MARK: - Public API

    /// Renders a Markdown string into a complete, self-contained HTML document.
    /// - Parameters:
    ///   - markdown: The Markdown source text.
    ///   - baseDirectory: Directory for resolving relative image paths.
    ///   - configuration: Rendering options.
    /// - Returns: A complete HTML document string.
    public func render(
        markdown: String,
        baseDirectory: URL,
        configuration: RenderConfiguration = .quickLook
    ) throws -> String {
        let parsed = parser.parse(markdown)
        let imageResolver = ImageResolver(baseDirectory: baseDirectory)

        // Resolve images in the HTML body
        var htmlBody = imageResolver.resolveImagesInHTML(
            parsed.html,
            embedImages: configuration.embedImages
        )

        // Convert mermaid code blocks to div elements
        if configuration.enableMermaid {
            htmlBody = convertMermaidBlocks(in: htmlBody)
        }

        return try renderHTMLBody(htmlBody, title: parsed.title ?? "Markdown Preview", configuration: configuration)
    }

    /// Wraps an arbitrary HTML body string in the full document template with themes and JS libraries.
    /// - Parameters:
    ///   - htmlBody: The inner HTML content to place in the document body.
    ///   - title: The document title. Defaults to "Preview".
    ///   - configuration: Rendering options controlling which JS/CSS features are included.
    /// - Returns: A complete, self-contained HTML document string.
    public func renderHTMLBody(
        _ htmlBody: String,
        title: String? = nil,
        configuration: RenderConfiguration = .quickLook
    ) throws -> String {
        // Load the template
        let template = try loadTemplate()

        // Determine effective theme
        let theme = configuration.theme ?? themeManager.effectiveTheme
        let themeCSS = try themeManager.loadCSS(for: theme)

        // Build the document
        var html = template
        html = html.replacingOccurrences(of: "{{TITLE}}", with: escapeHTML(title ?? "Preview"))
        html = html.replacingOccurrences(of: "{{THEME_CSS}}", with: themeCSS)
        html = html.replacingOccurrences(of: "{{BODY}}", with: htmlBody)

        // Highlight.js
        if configuration.enableHighlightJS {
            let hljsCSS = try loadHighlightCSS(for: theme)
            html = html.replacingOccurrences(of: "{{HIGHLIGHT_CSS}}", with: "<style>\(hljsCSS)</style>")
            let hljsJS = try loadResource(name: "highlight.min", ext: "js", subdirectory: "js")
            html = html.replacingOccurrences(
                of: "{{HIGHLIGHT_JS}}",
                with: "<script>\(hljsJS)</script>\n<script>hljs.highlightAll();</script>"
            )
        } else {
            html = html.replacingOccurrences(of: "{{HIGHLIGHT_CSS}}", with: "")
            html = html.replacingOccurrences(of: "{{HIGHLIGHT_JS}}", with: "")
        }

        // Mermaid
        if configuration.enableMermaid {
            let mermaidJS = try loadResource(name: "mermaid.min", ext: "js", subdirectory: "js")
            html = html.replacingOccurrences(
                of: "{{MERMAID_JS}}",
                with: "<script>\(mermaidJS)</script>\n<script>mermaid.initialize({startOnLoad:true,theme:'\(theme.isDark ? "dark" : "default")'});</script>"
            )
        } else {
            html = html.replacingOccurrences(of: "{{MERMAID_JS}}", with: "")
        }

        // KaTeX
        if configuration.enableKaTeX {
            let katexCSS = try loadKaTeXCSS()
            html = html.replacingOccurrences(of: "{{KATEX_CSS}}", with: "<style>\(katexCSS)</style>")
            let katexJS = try loadResource(name: "katex.min", ext: "js", subdirectory: "js")
            let autoRenderJS = try loadResource(name: "katex-auto-render.min", ext: "js", subdirectory: "js")
            let katexScript = """
            <script>\(katexJS)</script>
            <script>\(autoRenderJS)</script>
            <script>
            document.addEventListener("DOMContentLoaded", function() {
                renderMathInElement(document.body, {
                    delimiters: [
                        {left: "$$", right: "$$", display: true},
                        {left: "$", right: "$", display: false},
                        {left: "\\\\(", right: "\\\\)", display: false},
                        {left: "\\\\[", right: "\\\\]", display: true}
                    ],
                    throwOnError: false
                });
            });
            </script>
            """
            html = html.replacingOccurrences(of: "{{KATEX_JS}}", with: katexScript)
        } else {
            html = html.replacingOccurrences(of: "{{KATEX_CSS}}", with: "")
            html = html.replacingOccurrences(of: "{{KATEX_JS}}", with: "")
        }

        return html
    }

    /// Renders a Markdown file into a complete, self-contained HTML document.
    /// - Parameters:
    ///   - fileURL: URL of the Markdown file to render.
    ///   - configuration: Rendering options.
    /// - Returns: A complete HTML document string.
    public func render(
        fileURL: URL,
        configuration: RenderConfiguration = .quickLook
    ) throws -> String {
        let markdown = try String(contentsOf: fileURL, encoding: .utf8)
        let baseDirectory = fileURL.deletingLastPathComponent()
        return try render(markdown: markdown, baseDirectory: baseDirectory, configuration: configuration)
    }

    // MARK: - Mermaid Block Conversion

    /// Converts `<pre><code class="language-mermaid">...</code></pre>` blocks
    /// to `<div class="mermaid">...</div>` for mermaid.js rendering.
    private func convertMermaidBlocks(in html: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"<pre><code class="language-mermaid">([\s\S]*?)</code></pre>"#,
            options: []
        ) else {
            return html
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        var result = html
        for match in matches.reversed() {
            let contentRange = match.range(at: 1)
            let content = nsHTML.substring(with: contentRange)
            // Unescape HTML entities in mermaid content
            let unescaped = content
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")

            let replacement = "<div class=\"mermaid\">\(unescaped)</div>"
            let fullRange = Range(match.range(at: 0), in: result)!
            result.replaceSubrange(fullRange, with: replacement)
        }

        return result
    }

    // MARK: - Resource Loading

    private func loadTemplate() throws -> String {
        guard let url = Bundle.module.url(forResource: "template", withExtension: "html") else {
            throw RenderError.templateNotFound
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func loadResource(name: String, ext: String, subdirectory: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: subdirectory) else {
            throw RenderError.resourceNotFound("\(subdirectory)/\(name).\(ext)")
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func loadHighlightCSS(for theme: Theme) throws -> String {
        let cssName = theme.isDark ? "hljs-github-dark" : "hljs-github-light"
        return try loadResource(name: cssName, ext: "css", subdirectory: "css")
    }

    /// Loads KaTeX CSS with font URLs rewritten to inline data URIs.
    private func loadKaTeXCSS() throws -> String {
        var css = try loadResource(name: "katex.min", ext: "css", subdirectory: "css")

        // Replace font URL references with inline base64 data URIs
        guard let regex = try? NSRegularExpression(
            pattern: #"url\(fonts/([^)]+\.woff2)\)"#,
            options: []
        ) else {
            return css
        }

        let nsCSS = css as NSString
        let matches = regex.matches(in: css, range: NSRange(location: 0, length: nsCSS.length))

        for match in matches.reversed() {
            let fontNameRange = match.range(at: 1)
            let fontFilename = nsCSS.substring(with: fontNameRange)
            let fontName = (fontFilename as NSString).deletingPathExtension

            if let fontURL = Bundle.module.url(forResource: fontName, withExtension: "woff2", subdirectory: "fonts"),
               let fontData = try? Data(contentsOf: fontURL) {
                let base64 = fontData.base64EncodedString()
                let dataURI = "url(data:font/woff2;base64,\(base64))"
                let fullRange = Range(match.range(at: 0), in: css)!
                css.replaceSubrange(fullRange, with: dataURI)
            }
        }

        return css
    }

    // MARK: - Utility

    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
