import XCTest
@testable import HWPXShared

final class HeaderParserTests: XCTestCase {

    private let headerXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <hh:head xmlns:hh="http://www.hancom.co.kr/hwpml/2011/head">
      <hh:charProperties>
        <hh:charPr id="0" height="1000" textColor="#000000">
          <hh:fontRef hangul="맑은 고딕" latin="Arial"/>
        </hh:charPr>
        <hh:charPr id="1" height="1600" textColor="#000000">
          <hh:bold/>
          <hh:fontRef hangul="맑은 고딕" latin="Arial"/>
        </hh:charPr>
        <hh:charPr id="2" height="1000" textColor="#FF0000">
          <hh:italic/>
          <hh:fontRef hangul="맑은 고딕" latin="Arial"/>
        </hh:charPr>
      </hh:charProperties>
      <hh:paraProperties>
        <hh:paraPr id="0" align="LEFT"/>
        <hh:paraPr id="1" align="CENTER">
          <hh:heading type="OUTLINE" level="0"/>
        </hh:paraPr>
      </hh:paraProperties>
    </hh:head>
    """

    func testParseCharProperties() throws {
        let parser = HeaderParser()
        let styles = try parser.parse(xml: headerXML)

        XCTAssertEqual(styles.charProperties.count, 3)

        let normal = styles.charProperties[0]!
        XCTAssertEqual(normal.fontSize, 10.0) // 1000 / 100
        XCTAssertFalse(normal.isBold)
        XCTAssertFalse(normal.isItalic)
        XCTAssertEqual(normal.textColor, "#000000")
        XCTAssertEqual(normal.fontName, "맑은 고딕")
    }

    func testParseBold() throws {
        let parser = HeaderParser()
        let styles = try parser.parse(xml: headerXML)

        let bold = styles.charProperties[1]!
        XCTAssertTrue(bold.isBold)
        XCTAssertEqual(bold.fontSize, 16.0) // 1600 / 100
    }

    func testParseItalicAndColor() throws {
        let parser = HeaderParser()
        let styles = try parser.parse(xml: headerXML)

        let italic = styles.charProperties[2]!
        XCTAssertTrue(italic.isItalic)
        XCTAssertFalse(italic.isBold)
        XCTAssertEqual(italic.textColor, "#FF0000")
    }

    func testParseParaProperties() throws {
        let parser = HeaderParser()
        let styles = try parser.parse(xml: headerXML)

        XCTAssertEqual(styles.paraProperties.count, 2)

        let normal = styles.paraProperties[0]!
        XCTAssertEqual(normal.alignment, .left)
        XCTAssertNil(normal.outlineLevel)

        let heading = styles.paraProperties[1]!
        XCTAssertEqual(heading.alignment, .center)
        XCTAssertEqual(heading.outlineLevel, 0)
    }
}
