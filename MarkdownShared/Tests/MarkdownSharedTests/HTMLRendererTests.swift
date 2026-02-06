import XCTest
@testable import MarkdownShared

final class HTMLRendererTests: XCTestCase {

    let renderer = HTMLRenderer()
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HTMLRendererTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Basic Rendering

    func testRenderBasicMarkdown() throws {
        let md = "# Hello World\n\nThis is a test."
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<h1>Hello World</h1>"))
        XCTAssertTrue(html.contains("This is a test."))
        XCTAssertTrue(html.contains("</html>"))
    }

    func testRenderContainsThemeCSS() throws {
        let md = "# Test"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(theme: .githubLight, enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains(".markdown-body"))
        XCTAssertTrue(html.contains("background-color"))
    }

    func testRenderWithGithubDarkTheme() throws {
        let md = "# Dark"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(theme: .githubDark, enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("#0d1117"))
    }

    func testRenderWithDraculaTheme() throws {
        let md = "# Dracula"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(theme: .dracula, enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("#282a36"))
    }

    func testRenderWithNordTheme() throws {
        let md = "# Nord"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(theme: .nord, enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("#2e3440"))
    }

    // MARK: - Title

    func testTitleInHTML() throws {
        let md = "# My Document\n\nContent."
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("<title>My Document</title>"))
    }

    func testDefaultTitleWhenNoH1() throws {
        let md = "No heading here."
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("<title>Markdown Preview</title>"))
    }

    // MARK: - Feature Toggles

    func testHighlightJSEnabled() throws {
        let md = "```swift\nlet x = 1\n```"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: true, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("hljs.highlightAll()"))
        XCTAssertTrue(html.contains("hljs")) // highlight.js code
    }

    func testHighlightJSDisabled() throws {
        let md = "```swift\nlet x = 1\n```"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertFalse(html.contains("hljs.highlightAll()"))
    }

    func testMermaidEnabled() throws {
        let md = "```mermaid\ngraph TD;\n    A-->B;\n```"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: true, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("mermaid.initialize"))
        XCTAssertTrue(html.contains("<div class=\"mermaid\">"))
    }

    func testMermaidDisabled() throws {
        let md = "```mermaid\ngraph TD;\n    A-->B;\n```"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertFalse(html.contains("mermaid.initialize"))
        XCTAssertFalse(html.contains("<div class=\"mermaid\">"))
    }

    func testKaTeXEnabled() throws {
        let md = "Inline math: $E = mc^2$"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: false, enableKaTeX: true)
        )

        XCTAssertTrue(html.contains("renderMathInElement"))
        XCTAssertTrue(html.contains("katex"))
    }

    func testKaTeXDisabled() throws {
        let md = "No math."
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertFalse(html.contains("renderMathInElement"))
    }

    // MARK: - Image Embedding

    func testImageEmbedding() throws {
        // Create a test image
        let pngData = ImageResolverTests.minimalPNG()
        try pngData.write(to: tempDir.appendingPathComponent("test.png"))

        let md = "![Test](test.png)"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(embedImages: true, enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("data:image/png;base64,"))
    }

    func testImageNotEmbedded() throws {
        let pngData = ImageResolverTests.minimalPNG()
        try pngData.write(to: tempDir.appendingPathComponent("test.png"))

        let md = "![Test](test.png)"
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(embedImages: false, enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("file://"))
        XCTAssertFalse(html.contains("data:image/png;base64,"))
    }

    // MARK: - File-based Rendering

    func testRenderFromFile() throws {
        let md = "# From File\n\nHello from file."
        let fileURL = tempDir.appendingPathComponent("test.md")
        try md.write(to: fileURL, atomically: true, encoding: .utf8)

        let html = try renderer.render(
            fileURL: fileURL,
            configuration: .init(enableHighlightJS: false, enableMermaid: false, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("<h1>From File</h1>"))
        XCTAssertTrue(html.contains("Hello from file."))
    }

    // MARK: - Configuration Presets

    func testQuickLookPreset() {
        let config = RenderConfiguration.quickLook
        XCTAssertTrue(config.embedImages)
        XCTAssertTrue(config.enableHighlightJS)
        XCTAssertTrue(config.enableMermaid)
        XCTAssertTrue(config.enableKaTeX)
    }

    func testAppPreviewPreset() {
        let config = RenderConfiguration.appPreview
        XCTAssertFalse(config.embedImages)
        XCTAssertTrue(config.enableHighlightJS)
        XCTAssertTrue(config.enableMermaid)
        XCTAssertTrue(config.enableKaTeX)
    }

    // MARK: - Mermaid Block Conversion

    func testMermaidBlockConversion() throws {
        let md = """
        ```mermaid
        graph LR;
            A-->B;
            B-->C;
        ```
        """
        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .init(enableHighlightJS: false, enableMermaid: true, enableKaTeX: false)
        )

        XCTAssertTrue(html.contains("<div class=\"mermaid\">"))
        XCTAssertTrue(html.contains("A-->B"))
        // Should NOT contain the pre/code wrapper for mermaid
        XCTAssertFalse(html.contains("language-mermaid"))
    }

    // MARK: - Full Pipeline

    func testFullPipelineAllFeatures() throws {
        let md = """
        ---
        title: Full Test
        ---

        # Full Pipeline Test

        ## Code
        ```swift
        print("hello")
        ```

        ## Diagram
        ```mermaid
        graph TD;
            A-->B;
        ```

        ## Math
        Inline: $x^2$ and display:
        $$E = mc^2$$

        ## Table
        | A | B |
        |---|---|
        | 1 | 2 |
        """

        let html = try renderer.render(
            markdown: md,
            baseDirectory: tempDir,
            configuration: .quickLook
        )

        // Structure
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("</html>"))

        // Content
        XCTAssertTrue(html.contains("<h1>Full Pipeline Test</h1>"))
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("print("))

        // Features
        XCTAssertTrue(html.contains("hljs.highlightAll()"))
        XCTAssertTrue(html.contains("mermaid.initialize"))
        XCTAssertTrue(html.contains("renderMathInElement"))
    }
}
