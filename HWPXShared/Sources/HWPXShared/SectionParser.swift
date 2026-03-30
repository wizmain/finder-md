import Foundation

/// Parses HWPX section XML (section*.xml) into document model elements.
public final class SectionParser: NSObject {

    private var elements: [HWPXBlockElement] = []

    // Parser state
    private var currentParagraph: HWPXParagraph?
    private var currentRun: HWPXRun?
    private var currentText: String = ""
    private var isInsideText = false

    // Table state
    private var tableStack: [TableParseState] = []
    private var currentTable: HWPXTable?
    private var currentRow: HWPXTableRow?
    private var currentCell: HWPXTableCell?
    private var isInsideTable: Bool { !tableStack.isEmpty }

    // Image state
    private var currentImageRef: String?
    private var isInsidePic = false

    private var parserError: Error?

    private struct TableParseState {
        var table: HWPXTable
        var row: HWPXTableRow?
        var cell: HWPXTableCell?
    }

    /// Parse a section XML string into a list of block elements.
    public func parse(xml: String) throws -> [HWPXBlockElement] {
        let data = Data(xml.utf8)
        return try parse(data: data)
    }

    /// Parse section XML data into a list of block elements.
    public func parse(data: Data) throws -> [HWPXBlockElement] {
        elements = []
        currentParagraph = nil
        currentRun = nil
        currentText = ""
        isInsideText = false
        tableStack = []
        currentImageRef = nil
        isInsidePic = false
        parserError = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.shouldReportNamespacePrefixes = false

        guard parser.parse() else {
            if let error = parserError {
                throw error
            }
            throw HWPXError.parsingFailed("Section XML parsing failed")
        }

        return elements
    }

    // MARK: - Helpers

    private func finishCurrentRun() {
        guard var run = currentRun else { return }
        run.text = currentText
        currentText = ""

        if isInsideTable, tableStack.last != nil {
            // Inside a table cell — append to cell's paragraph
            if var cellPara = currentParagraph {
                cellPara.runs.append(run)
                currentParagraph = cellPara
            }
        } else if var para = currentParagraph {
            para.runs.append(run)
            currentParagraph = para
        }
        currentRun = nil
    }

    private func finishCurrentParagraph() {
        finishCurrentRun()
        guard let para = currentParagraph else { return }

        if isInsideTable {
            if let state = tableStack.last, state.cell != nil {
                tableStack[tableStack.count - 1].cell!.paragraphs.append(para)
            }
        } else {
            if !para.isEmpty || para.isHeading {
                elements.append(.paragraph(para))
            }
        }
        currentParagraph = nil
    }

    private func localName(from qualifiedName: String) -> String {
        if let colonIndex = qualifiedName.firstIndex(of: ":") {
            return String(qualifiedName[qualifiedName.index(after: colonIndex)...])
        }
        return qualifiedName
    }
}

// MARK: - XMLParserDelegate

extension SectionParser: XMLParserDelegate {

    public func parser(_ parser: XMLParser, didStartElement elementName: String,
                       namespaceURI: String?, qualifiedName qName: String?,
                       attributes: [String: String] = [:]) {
        let local = localName(from: qName ?? elementName)

        switch local {
        case "p":
            finishCurrentParagraph()
            let styleRef = attributes["paraPrIDRef"].flatMap(Int.init)
            currentParagraph = HWPXParagraph(styleRef: styleRef)

        case "run":
            finishCurrentRun()
            let charRef = attributes["charPrIDRef"].flatMap(Int.init)
            currentRun = HWPXRun(charStyleRef: charRef)
            currentText = ""

        case "t":
            isInsideText = true

        case "tbl":
            finishCurrentParagraph()
            let colCount = attributes["colCnt"].flatMap(Int.init) ?? 0
            let table = HWPXTable(columnCount: colCount)
            tableStack.append(TableParseState(table: table))

        case "tr":
            if !tableStack.isEmpty {
                tableStack[tableStack.count - 1].row = HWPXTableRow()
            }

        case "tc":
            if !tableStack.isEmpty {
                let colSpan = attributes["colSpan"].flatMap(Int.init) ?? 1
                let rowSpan = attributes["rowSpan"].flatMap(Int.init) ?? 1
                tableStack[tableStack.count - 1].cell = HWPXTableCell(colSpan: colSpan, rowSpan: rowSpan)
            }

        case "subList":
            // Content inside table cells uses subList — just continue parsing paragraphs
            break

        case "pic":
            isInsidePic = true

        case "binItem":
            if isInsidePic, let src = attributes["src"] {
                currentImageRef = src
            }

        case "img":
            // Primary image reference: <img binaryItemIDRef="image1"/>
            if isInsidePic, let ref = attributes["binaryItemIDRef"] {
                currentImageRef = ref
            } else if let src = attributes["src"] {
                currentImageRef = src
            }

        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String,
                       namespaceURI: String?, qualifiedName qName: String?) {
        let local = localName(from: qName ?? elementName)

        switch local {
        case "p":
            finishCurrentParagraph()

        case "run":
            finishCurrentRun()

        case "t":
            isInsideText = false

        case "tbl":
            guard let state = tableStack.popLast() else { break }
            let table = state.table
            if isInsideTable {
                // Nested table — add as element in outer table's cell
                // For simplicity, flatten nested tables
            }
            elements.append(.table(table))

        case "tr":
            if !tableStack.isEmpty, let row = tableStack[tableStack.count - 1].row {
                tableStack[tableStack.count - 1].table.rows.append(row)
                tableStack[tableStack.count - 1].row = nil
            }

        case "tc":
            if !tableStack.isEmpty, let cell = tableStack[tableStack.count - 1].cell {
                if tableStack[tableStack.count - 1].row != nil {
                    tableStack[tableStack.count - 1].row!.cells.append(cell)
                }
                tableStack[tableStack.count - 1].cell = nil
            }

        case "pic":
            if let imageRef = currentImageRef, var run = currentRun {
                run.imageRef = imageRef
                currentRun = run
            } else if let imageRef = currentImageRef {
                // Image outside a run — create a synthetic run
                var imgRun = HWPXRun()
                imgRun.imageRef = imageRef
                if var para = currentParagraph {
                    para.runs.append(imgRun)
                    currentParagraph = para
                }
            }
            isInsidePic = false
            currentImageRef = nil

        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInsideText {
            currentText += string
        }
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parserError = parseError
    }
}
