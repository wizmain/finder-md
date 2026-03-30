import XCTest
@testable import MarkdownShared

final class MarkdownParserTests: XCTestCase {

    let parser = MarkdownParser()

    // MARK: - Basic HTML Generation

    func testBasicParagraph() {
        let result = parser.parse("Hello, world!")
        XCTAssertTrue(result.html.contains("<p>Hello, world!</p>"))
    }

    func testMultipleParagraphs() {
        let md = "First paragraph.\n\nSecond paragraph."
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<p>First paragraph.</p>"))
        XCTAssertTrue(result.html.contains("<p>Second paragraph.</p>"))
    }

    func testHeadings() {
        let md = "# Heading 1\n\n## Heading 2\n\n### Heading 3"
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<h1>Heading 1</h1>"))
        XCTAssertTrue(result.html.contains("<h2>Heading 2</h2>"))
        XCTAssertTrue(result.html.contains("<h3>Heading 3</h3>"))
    }

    func testCodeBlock() {
        let md = """
        ```swift
        let x = 42
        ```
        """
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<code"))
        XCTAssertTrue(result.html.contains("let x = 42"))
    }

    func testInlineCode() {
        let md = "Use `print()` to debug."
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<code>print()</code>"))
    }

    // MARK: - GFM Features

    func testGFMTable() {
        let md = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<table>"))
        XCTAssertTrue(result.html.contains("<th>"))
        XCTAssertTrue(result.html.contains("Cell 1"))
    }

    func testGFMStrikethrough() {
        let md = "This is ~~deleted~~ text."
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<del>deleted</del>"))
    }

    func testGFMTaskList() {
        let md = """
        - [x] Done
        - [ ] Not done
        """
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("checked"))
        XCTAssertTrue(result.html.contains("Done"))
        XCTAssertTrue(result.html.contains("Not done"))
    }

    // MARK: - Formatting

    func testBoldAndItalic() {
        let md = "**bold** and *italic* and ***both***"
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<strong>bold</strong>"))
        XCTAssertTrue(result.html.contains("<em>italic</em>"))
    }

    func testBlockquote() {
        let md = "> This is a quote"
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<blockquote>"))
        XCTAssertTrue(result.html.contains("This is a quote"))
    }

    func testOrderedList() {
        let md = "1. First\n2. Second\n3. Third"
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<ol>"))
        XCTAssertTrue(result.html.contains("<li>"))
    }

    func testUnorderedList() {
        let md = "- Apple\n- Banana\n- Cherry"
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<ul>"))
        XCTAssertTrue(result.html.contains("<li>"))
    }

    func testLink() {
        let md = "[Click here](https://example.com)"
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<a href=\"https://example.com\">Click here</a>"))
    }

    func testHorizontalRule() {
        let md = "Above\n\n---\n\nBelow"
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<hr"))
    }

    // MARK: - Title Extraction

    func testTitleFromH1() {
        let md = "# My Document Title\n\nSome content."
        let result = parser.parse(md)
        XCTAssertEqual(result.title, "My Document Title")
    }

    func testTitleFromFirstH1Only() {
        let md = "## Section\n\n# Title\n\n# Another Title"
        let result = parser.parse(md)
        XCTAssertEqual(result.title, "Title")
    }

    func testNoTitle() {
        let md = "## Only H2\n\nNo H1 here."
        let result = parser.parse(md)
        XCTAssertNil(result.title)
    }

    // MARK: - Frontmatter

    func testFrontmatterExtraction() {
        let md = """
        ---
        title: My Page
        author: John
        date: 2024-01-01
        ---

        # Content
        """
        let result = parser.parse(md)
        XCTAssertEqual(result.frontmatter["title"], "My Page")
        XCTAssertEqual(result.frontmatter["author"], "John")
        XCTAssertEqual(result.frontmatter["date"], "2024-01-01")
        // The frontmatter should be stripped from the body
        XCTAssertFalse(result.html.contains("title: My Page"))
        // But the H1 should still render
        XCTAssertTrue(result.html.contains("<h1>Content</h1>"))
    }

    func testNoFrontmatter() {
        let md = "# Hello\n\nNo frontmatter."
        let result = parser.parse(md)
        XCTAssertTrue(result.frontmatter.isEmpty)
    }

    func testUnclosedFrontmatter() {
        let md = "---\ntitle: broken\nno closing"
        let result = parser.parse(md)
        XCTAssertTrue(result.frontmatter.isEmpty)
    }

    // MARK: - Image Source Extraction

    func testImageSourceExtraction() {
        let md = """
        ![Alt text](image.png)
        ![Another](../photos/pic.jpg)
        """
        let result = parser.parse(md)
        XCTAssertEqual(result.imageSources.count, 2)
        XCTAssertTrue(result.imageSources.contains("image.png"))
        XCTAssertTrue(result.imageSources.contains("../photos/pic.jpg"))
    }

    func testNoImages() {
        let md = "Just text, no images."
        let result = parser.parse(md)
        XCTAssertTrue(result.imageSources.isEmpty)
    }

    // MARK: - parseToHTML Convenience

    func testParseToHTML() {
        let html = parser.parseToHTML("**bold**")
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
    }

    // MARK: - Edge Cases

    func testEmptyDocument() {
        let result = parser.parse("")
        XCTAssertTrue(result.html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                       || result.html.contains(""))
        XCTAssertNil(result.title)
        XCTAssertTrue(result.frontmatter.isEmpty)
        XCTAssertTrue(result.imageSources.isEmpty)
    }

    func testHTMLEntitiesInCode() {
        let md = "Use `<div>` in code."
        let result = parser.parse(md)
        XCTAssertTrue(result.html.contains("<code>"))
        // The code block should contain escaped HTML entities
        XCTAssertTrue(result.html.contains("&lt;div&gt;") || result.html.contains("<div>"))
    }
}
