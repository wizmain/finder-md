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

    // MARK: - cellSpan child element

    func testParseCellSpanChildElement() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"
                xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">
          <hp:tbl colCnt="3" rowCnt="1">
            <hp:tr>
              <hp:tc name="" header="0">
                <hp:subList>
                  <hp:p paraPrIDRef="0">
                    <hp:run charPrIDRef="0"><hp:t>Merged</hp:t></hp:run>
                  </hp:p>
                </hp:subList>
                <hp:cellAddr colAddr="0" rowAddr="0"/>
                <hp:cellSpan colSpan="2" rowSpan="3"/>
                <hp:cellSz width="100" height="50"/>
              </hp:tc>
              <hp:tc name="" header="0">
                <hp:subList>
                  <hp:p paraPrIDRef="0">
                    <hp:run charPrIDRef="0"><hp:t>Single</hp:t></hp:run>
                  </hp:p>
                </hp:subList>
                <hp:cellSpan colSpan="1" rowSpan="1"/>
              </hp:tc>
            </hp:tr>
          </hp:tbl>
        </hs:sec>
        """

        let parser = SectionParser()
        let elements = try parser.parse(xml: xml)

        guard case .table(let table) = elements[0] else {
            XCTFail("Expected table"); return
        }
        XCTAssertEqual(table.rows[0].cells[0].colSpan, 2)
        XCTAssertEqual(table.rows[0].cells[0].rowSpan, 3)
        XCTAssertEqual(table.rows[0].cells[0].paragraphs[0].runs[0].text, "Merged")
        XCTAssertEqual(table.rows[0].cells[1].colSpan, 1)
        XCTAssertEqual(table.rows[0].cells[1].rowSpan, 1)
    }

    // MARK: - Table inside run (real HWPX structure)

    func testParseTableInsideRun() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"
                xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">
          <hp:p paraPrIDRef="0">
            <hp:run charPrIDRef="0">
              <hp:tbl colCnt="2" rowCnt="1">
                <hp:tr>
                  <hp:tc>
                    <hp:subList>
                      <hp:p paraPrIDRef="0">
                        <hp:run charPrIDRef="0"><hp:t>Cell A</hp:t></hp:run>
                      </hp:p>
                    </hp:subList>
                  </hp:tc>
                  <hp:tc>
                    <hp:subList>
                      <hp:p paraPrIDRef="0">
                        <hp:run charPrIDRef="0"><hp:t>Cell B</hp:t></hp:run>
                      </hp:p>
                    </hp:subList>
                  </hp:tc>
                </hp:tr>
              </hp:tbl>
              <hp:t/>
            </hp:run>
          </hp:p>
        </hs:sec>
        """

        let parser = SectionParser()
        let elements = try parser.parse(xml: xml)

        // Table should be extracted even though nested inside p > run
        let tables = elements.compactMap { if case .table(let t) = $0 { return t } else { return nil } }
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables[0].rows[0].cells[0].paragraphs[0].runs[0].text, "Cell A")
        XCTAssertEqual(tables[0].rows[0].cells[1].paragraphs[0].runs[0].text, "Cell B")
    }

    // MARK: - lineBreak

    func testParseLineBreak() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"
                xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph">
          <hp:p paraPrIDRef="0">
            <hp:run charPrIDRef="0">
              <hp:t>Line one<hp:lineBreak/>Line two</hp:t>
            </hp:run>
          </hp:p>
        </hs:sec>
        """

        let parser = SectionParser()
        let elements = try parser.parse(xml: xml)

        guard case .paragraph(let para) = elements[0] else {
            XCTFail("Expected paragraph"); return
        }
        XCTAssertTrue(para.runs[0].text.contains("\n"))
        XCTAssertTrue(para.runs[0].text.contains("Line one"))
        XCTAssertTrue(para.runs[0].text.contains("Line two"))
    }

    // MARK: - Page background image detection

    func testPageBackgroundImageDetection() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <hs:sec xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section"
                xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph"
                xmlns:hc="http://www.hancom.co.kr/hwpml/2011/core">
          <hp:p paraPrIDRef="0">
            <hp:run charPrIDRef="0">
              <hp:secPr>
                <hp:pagePr width="61228" height="85889"/>
              </hp:secPr>
            </hp:run>
            <hp:run charPrIDRef="0">
              <hp:pic id="1" zOrder="0" numberingType="PICTURE" textWrap="TOP_AND_BOTTOM">
                <hp:curSz width="61228" height="85889"/>
                <hc:img binaryItemIDRef="background"/>
              </hp:pic>
            </hp:run>
            <hp:run charPrIDRef="0">
              <hp:pic id="2" zOrder="1" numberingType="PICTURE" textWrap="TOP_AND_BOTTOM">
                <hp:curSz width="5000" height="3000"/>
                <hc:img binaryItemIDRef="logo"/>
              </hp:pic>
            </hp:run>
          </hp:p>
        </hs:sec>
        """

        let parser = SectionParser()
        let elements = try parser.parse(xml: xml)

        guard case .paragraph(let para) = elements[0] else {
            XCTFail("Expected paragraph"); return
        }
        // Run with background image should be marked as page background
        let bgRun = para.runs.first(where: { $0.imageRef == "background" })
        XCTAssertNotNil(bgRun)
        XCTAssertTrue(bgRun!.isPageBackground)

        // Run with small image should NOT be marked as page background
        let logoRun = para.runs.first(where: { $0.imageRef == "logo" })
        XCTAssertNotNil(logoRun)
        XCTAssertFalse(logoRun!.isPageBackground)
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
