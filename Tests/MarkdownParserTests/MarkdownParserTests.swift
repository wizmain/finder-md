import XCTest

final class MarkdownParserTests: XCTestCase {
    func testRenderHTMLWrapsOutput() {
        let parser = MarkdownParser()
        let html = parser.renderHTML(from: "# Title")
        XCTAssertTrue(html.contains("<pre>"))
    }
}
