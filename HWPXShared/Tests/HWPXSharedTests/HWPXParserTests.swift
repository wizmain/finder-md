import XCTest
@testable import HWPXShared

final class HWPXParserTests: XCTestCase {

    private var fixtureURL: URL {
        Bundle.module.url(forResource: "sample", withExtension: "hwpx", subdirectory: "Fixtures")!
    }

    func testParseDocument() throws {
        let parser = HWPXParser()
        let document = try parser.parse(fileURL: fixtureURL)

        XCTAssertFalse(document.sections.isEmpty)
        XCTAssertEqual(document.sections.count, 1)
    }

    func testDocumentHasContent() throws {
        let parser = HWPXParser()
        let document = try parser.parse(fileURL: fixtureURL)

        let plainText = document.plainText
        XCTAssertTrue(plainText.contains("테스트 문서 제목"))
        XCTAssertTrue(plainText.contains("Hello World"))
    }

    func testDocumentTitle() throws {
        let parser = HWPXParser()
        let document = try parser.parse(fileURL: fixtureURL)

        // Title should be extracted from the first heading
        XCTAssertEqual(document.title, "테스트 문서 제목")
    }

    func testStylesLoaded() throws {
        let parser = HWPXParser()
        let document = try parser.parse(fileURL: fixtureURL)

        XCTAssertFalse(document.styles.charProperties.isEmpty)
        XCTAssertFalse(document.styles.paraProperties.isEmpty)
    }

    func testParseToHTML() throws {
        let parser = HWPXParser()
        let html = try parser.parseToHTML(fileURL: fixtureURL)

        XCTAssertFalse(html.isEmpty)
        XCTAssertTrue(html.contains("테스트 문서 제목"))
        XCTAssertTrue(html.contains("Hello World"))
    }

    func testHeadingsResolved() throws {
        let parser = HWPXParser()
        let document = try parser.parse(fileURL: fixtureURL)

        // First paragraph should be a heading (paraPrIDRef=1 has heading level=0)
        let firstElement = document.sections[0].elements[0]
        guard case .paragraph(let para) = firstElement else {
            XCTFail("Expected paragraph"); return
        }
        XCTAssertTrue(para.isHeading)
        XCTAssertEqual(para.headingLevel, 1) // 0-based -> 1-based
    }

    func testTableParsed() throws {
        let parser = HWPXParser()
        let document = try parser.parse(fileURL: fixtureURL)

        let elements = document.sections[0].elements
        let tables = elements.compactMap { element -> HWPXTable? in
            guard case .table(let table) = element else { return nil }
            return table
        }

        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables[0].rows.count, 2)
        XCTAssertEqual(tables[0].rows[0].cells.count, 2)
    }
}
