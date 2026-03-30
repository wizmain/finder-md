import XCTest
@testable import HWPXShared

final class HWPXHTMLGeneratorTests: XCTestCase {

    func testBasicParagraph() {
        let doc = HWPXDocument(
            sections: [
                HWPXSection(elements: [
                    .paragraph(HWPXParagraph(runs: [HWPXRun(text: "Hello World")]))
                ])
            ]
        )

        let generator = HWPXHTMLGenerator()
        let html = generator.generateHTML(from: doc)

        XCTAssertTrue(html.contains("<p>Hello World</p>"))
    }

    func testHeadingParagraph() {
        let doc = HWPXDocument(
            sections: [
                HWPXSection(elements: [
                    .paragraph(HWPXParagraph(
                        runs: [HWPXRun(text: "Title")],
                        isHeading: true,
                        headingLevel: 1
                    ))
                ])
            ]
        )

        let generator = HWPXHTMLGenerator()
        let html = generator.generateHTML(from: doc)

        XCTAssertTrue(html.contains("<h1>Title</h1>"))
    }

    func testBoldAndItalicStyling() {
        let styles = HWPXStyleSheet(
            charProperties: [
                0: HWPXCharProperties(id: 0, isBold: true),
                1: HWPXCharProperties(id: 1, isItalic: true)
            ]
        )
        let doc = HWPXDocument(
            sections: [
                HWPXSection(elements: [
                    .paragraph(HWPXParagraph(runs: [
                        HWPXRun(text: "Bold", charStyleRef: 0),
                        HWPXRun(text: " Italic", charStyleRef: 1)
                    ]))
                ])
            ],
            styles: styles
        )

        let generator = HWPXHTMLGenerator()
        let html = generator.generateHTML(from: doc)

        XCTAssertTrue(html.contains("<strong>Bold</strong>"))
        XCTAssertTrue(html.contains("<em> Italic</em>"))
    }

    func testColoredText() {
        let styles = HWPXStyleSheet(
            charProperties: [
                0: HWPXCharProperties(id: 0, textColor: "#FF0000")
            ]
        )
        let doc = HWPXDocument(
            sections: [
                HWPXSection(elements: [
                    .paragraph(HWPXParagraph(runs: [
                        HWPXRun(text: "Red text", charStyleRef: 0)
                    ]))
                ])
            ],
            styles: styles
        )

        let generator = HWPXHTMLGenerator()
        let html = generator.generateHTML(from: doc)

        XCTAssertTrue(html.contains("color:#FF0000"))
    }

    func testTableRendering() {
        let doc = HWPXDocument(
            sections: [
                HWPXSection(elements: [
                    .table(HWPXTable(rows: [
                        HWPXTableRow(cells: [
                            HWPXTableCell(paragraphs: [
                                HWPXParagraph(runs: [HWPXRun(text: "Cell 1")])
                            ]),
                            HWPXTableCell(paragraphs: [
                                HWPXParagraph(runs: [HWPXRun(text: "Cell 2")])
                            ])
                        ])
                    ], columnCount: 2))
                ])
            ]
        )

        let generator = HWPXHTMLGenerator()
        let html = generator.generateHTML(from: doc)

        XCTAssertTrue(html.contains("<table"))
        XCTAssertTrue(html.contains("<td"))
        XCTAssertTrue(html.contains("Cell 1"))
        XCTAssertTrue(html.contains("Cell 2"))
    }

    func testHTMLEscaping() {
        let doc = HWPXDocument(
            sections: [
                HWPXSection(elements: [
                    .paragraph(HWPXParagraph(runs: [
                        HWPXRun(text: "<script>alert('xss')</script>")
                    ]))
                ])
            ]
        )

        let generator = HWPXHTMLGenerator()
        let html = generator.generateHTML(from: doc)

        XCTAssertFalse(html.contains("<script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testDocumentTitle() {
        let doc = HWPXDocument(
            sections: [
                HWPXSection(elements: [
                    .paragraph(HWPXParagraph(
                        runs: [HWPXRun(text: "My Title")],
                        isHeading: true,
                        headingLevel: 1
                    )),
                    .paragraph(HWPXParagraph(runs: [HWPXRun(text: "Body")]))
                ])
            ]
        )

        XCTAssertEqual(doc.title, "My Title")
    }

    func testDocumentPlainText() {
        let doc = HWPXDocument(
            sections: [
                HWPXSection(elements: [
                    .paragraph(HWPXParagraph(runs: [HWPXRun(text: "Line 1")])),
                    .paragraph(HWPXParagraph(runs: [HWPXRun(text: "Line 2")]))
                ])
            ]
        )

        let text = doc.plainText
        XCTAssertTrue(text.contains("Line 1"))
        XCTAssertTrue(text.contains("Line 2"))
    }
}
