import XCTest
@testable import HWPXShared

final class SectionParserTests: XCTestCase {

    private let sectionXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"
            xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">
      <hp:p paraPrIDRef="0">
        <hp:run charPrIDRef="0">
          <hp:t>Hello World</hp:t>
        </hp:run>
      </hp:p>
      <hp:p paraPrIDRef="0">
        <hp:run charPrIDRef="1">
          <hp:t>Bold text</hp:t>
        </hp:run>
        <hp:run charPrIDRef="0">
          <hp:t> normal text</hp:t>
        </hp:run>
      </hp:p>
    </hs:sec>
    """

    func testParseParagraphs() throws {
        let parser = SectionParser()
        let elements = try parser.parse(xml: sectionXML)

        XCTAssertEqual(elements.count, 2)

        guard case .paragraph(let para1) = elements[0] else {
            XCTFail("Expected paragraph"); return
        }
        XCTAssertEqual(para1.runs.count, 1)
        XCTAssertEqual(para1.runs[0].text, "Hello World")
    }

    func testParseMultipleRuns() throws {
        let parser = SectionParser()
        let elements = try parser.parse(xml: sectionXML)

        guard case .paragraph(let para2) = elements[1] else {
            XCTFail("Expected paragraph"); return
        }
        XCTAssertEqual(para2.runs.count, 2)
        XCTAssertEqual(para2.runs[0].text, "Bold text")
        XCTAssertEqual(para2.runs[0].charStyleRef, 1)
        XCTAssertEqual(para2.runs[1].text, " normal text")
    }

    func testParseStyleRefs() throws {
        let parser = SectionParser()
        let elements = try parser.parse(xml: sectionXML)

        guard case .paragraph(let para) = elements[0] else {
            XCTFail("Expected paragraph"); return
        }
        XCTAssertEqual(para.styleRef, 0)
        XCTAssertEqual(para.runs[0].charStyleRef, 0)
    }

    func testParseTable() throws {
        let tableXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"
                xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">
          <hp:tbl colCnt="2" rowCnt="2">
            <hp:tr>
              <hp:tc>
                <hp:subList>
                  <hp:p paraPrIDRef="0">
                    <hp:run charPrIDRef="0"><hp:t>A1</hp:t></hp:run>
                  </hp:p>
                </hp:subList>
              </hp:tc>
              <hp:tc>
                <hp:subList>
                  <hp:p paraPrIDRef="0">
                    <hp:run charPrIDRef="0"><hp:t>B1</hp:t></hp:run>
                  </hp:p>
                </hp:subList>
              </hp:tc>
            </hp:tr>
            <hp:tr>
              <hp:tc>
                <hp:subList>
                  <hp:p paraPrIDRef="0">
                    <hp:run charPrIDRef="0"><hp:t>A2</hp:t></hp:run>
                  </hp:p>
                </hp:subList>
              </hp:tc>
              <hp:tc>
                <hp:subList>
                  <hp:p paraPrIDRef="0">
                    <hp:run charPrIDRef="0"><hp:t>B2</hp:t></hp:run>
                  </hp:p>
                </hp:subList>
              </hp:tc>
            </hp:tr>
          </hp:tbl>
        </hs:sec>
        """

        let parser = SectionParser()
        let elements = try parser.parse(xml: tableXML)

        XCTAssertEqual(elements.count, 1)
        guard case .table(let table) = elements[0] else {
            XCTFail("Expected table"); return
        }
        XCTAssertEqual(table.rows.count, 2)
        XCTAssertEqual(table.rows[0].cells.count, 2)
        XCTAssertEqual(table.rows[0].cells[0].paragraphs[0].runs[0].text, "A1")
        XCTAssertEqual(table.rows[1].cells[1].paragraphs[0].runs[0].text, "B2")
    }

    func testParseKoreanText() throws {
        let koreanXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"
                xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">
          <hp:p paraPrIDRef="0">
            <hp:run charPrIDRef="0">
              <hp:t>한글 테스트 문서입니다.</hp:t>
            </hp:run>
          </hp:p>
        </hs:sec>
        """

        let parser = SectionParser()
        let elements = try parser.parse(xml: koreanXML)

        guard case .paragraph(let para) = elements[0] else {
            XCTFail("Expected paragraph"); return
        }
        XCTAssertEqual(para.runs[0].text, "한글 테스트 문서입니다.")
    }

    func testEmptySection() throws {
        let emptyXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"
                xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">
        </hs:sec>
        """

        let parser = SectionParser()
        let elements = try parser.parse(xml: emptyXML)
        XCTAssertTrue(elements.isEmpty)
    }
}
