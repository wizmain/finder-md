import XCTest
@testable import HWPXShared

final class HWPXArchiveTests: XCTestCase {

    private var fixtureURL: URL {
        Bundle.module.url(forResource: "sample", withExtension: "hwpx", subdirectory: "Fixtures")!
    }

    func testOpenArchive() throws {
        let archive = try HWPXArchive(fileURL: fixtureURL)
        let entries = archive.listEntries()
        XCTAssertFalse(entries.isEmpty)
    }

    func testListEntries() throws {
        let archive = try HWPXArchive(fileURL: fixtureURL)
        let entries = archive.listEntries()
        XCTAssertTrue(entries.contains("mimetype"))
        XCTAssertTrue(entries.contains("Contents/header.xml"))
        XCTAssertTrue(entries.contains("Contents/section0.xml"))
    }

    func testExtractMimetype() throws {
        let archive = try HWPXArchive(fileURL: fixtureURL)
        let mimetype = try archive.extractString(at: "mimetype")
        XCTAssertEqual(mimetype, "application/haansofthwpx")
    }

    func testExtractHeaderXML() throws {
        let archive = try HWPXArchive(fileURL: fixtureURL)
        let header = try archive.extractString(at: "Contents/header.xml")
        XCTAssertTrue(header.contains("charPr"))
        XCTAssertTrue(header.contains("paraPr"))
    }

    func testExtractSectionXML() throws {
        let archive = try HWPXArchive(fileURL: fixtureURL)
        let section = try archive.extractString(at: "Contents/section0.xml")
        XCTAssertTrue(section.contains("테스트 문서 제목"))
    }

    func testPreviewText() throws {
        let archive = try HWPXArchive(fileURL: fixtureURL)
        let text = archive.previewText()
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("테스트 문서 제목"))
    }

    func testListEntriesWithPrefix() throws {
        let archive = try HWPXArchive(fileURL: fixtureURL)
        let contentEntries = archive.listEntries(prefix: "Contents/")
        XCTAssertTrue(contentEntries.contains("Contents/header.xml"))
        XCTAssertTrue(contentEntries.contains("Contents/section0.xml"))
    }

    func testEntryNotFoundError() throws {
        let archive = try HWPXArchive(fileURL: fixtureURL)
        XCTAssertThrowsError(try archive.extractData(at: "nonexistent.xml")) { error in
            guard case HWPXError.entryNotFound = error else {
                XCTFail("Expected entryNotFound error")
                return
            }
        }
    }
}
