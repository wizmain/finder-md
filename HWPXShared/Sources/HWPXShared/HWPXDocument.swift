import Foundation

/// Represents a parsed HWPX document.
public struct HWPXDocument {
    public var sections: [HWPXSection]
    public var styles: HWPXStyleSheet
    public var images: [String: Data]

    public init(sections: [HWPXSection] = [], styles: HWPXStyleSheet = HWPXStyleSheet(), images: [String: Data] = [:]) {
        self.sections = sections
        self.styles = styles
        self.images = images
    }

    /// Extract the document title from the first heading paragraph.
    public var title: String? {
        for section in sections {
            for element in section.elements {
                if case .paragraph(let para) = element, para.isHeading {
                    return para.plainText
                }
            }
        }
        return nil
    }

    /// Extract all plain text from the document.
    public var plainText: String {
        sections.map { section in
            section.elements.compactMap { element -> String? in
                switch element {
                case .paragraph(let para):
                    return para.plainText
                case .table(let table):
                    return table.plainText
                }
            }.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }
}

/// A section of the document (corresponds to one section*.xml file).
public struct HWPXSection {
    public var elements: [HWPXBlockElement]

    public init(elements: [HWPXBlockElement] = []) {
        self.elements = elements
    }
}

/// Block-level elements in a section.
public enum HWPXBlockElement {
    case paragraph(HWPXParagraph)
    case table(HWPXTable)
}

/// A paragraph containing text runs.
public struct HWPXParagraph {
    public var runs: [HWPXRun]
    public var styleRef: Int?
    public var isHeading: Bool
    public var headingLevel: Int

    public init(runs: [HWPXRun] = [], styleRef: Int? = nil, isHeading: Bool = false, headingLevel: Int = 0) {
        self.runs = runs
        self.styleRef = styleRef
        self.isHeading = isHeading
        self.headingLevel = headingLevel
    }

    public var plainText: String {
        runs.map(\.text).joined()
    }

    public var isEmpty: Bool {
        runs.allSatisfy { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

/// A text run with optional styling.
public struct HWPXRun {
    public var text: String
    public var charStyleRef: Int?
    public var imageRef: String?

    public init(text: String = "", charStyleRef: Int? = nil, imageRef: String? = nil) {
        self.text = text
        self.charStyleRef = charStyleRef
        self.imageRef = imageRef
    }
}

/// A table element.
public struct HWPXTable {
    public var rows: [HWPXTableRow]
    public var columnCount: Int

    public init(rows: [HWPXTableRow] = [], columnCount: Int = 0) {
        self.rows = rows
        self.columnCount = columnCount
    }

    public var plainText: String {
        rows.map { row in
            row.cells.map { cell in
                cell.paragraphs.map(\.plainText).joined(separator: " ")
            }.joined(separator: "\t")
        }.joined(separator: "\n")
    }
}

/// A table row.
public struct HWPXTableRow {
    public var cells: [HWPXTableCell]

    public init(cells: [HWPXTableCell] = []) {
        self.cells = cells
    }
}

/// A table cell containing paragraphs.
public struct HWPXTableCell {
    public var paragraphs: [HWPXParagraph]
    public var colSpan: Int
    public var rowSpan: Int

    public init(paragraphs: [HWPXParagraph] = [], colSpan: Int = 1, rowSpan: Int = 1) {
        self.paragraphs = paragraphs
        self.colSpan = colSpan
        self.rowSpan = rowSpan
    }
}

// MARK: - Style Definitions

/// Character properties parsed from header.xml.
public struct HWPXCharProperties {
    public var id: Int
    public var fontName: String?
    public var fontSize: Double?
    public var isBold: Bool
    public var isItalic: Bool
    public var isStrikethrough: Bool
    public var isUnderline: Bool
    public var textColor: String?

    public init(id: Int, fontName: String? = nil, fontSize: Double? = nil,
                isBold: Bool = false, isItalic: Bool = false,
                isStrikethrough: Bool = false, isUnderline: Bool = false,
                textColor: String? = nil) {
        self.id = id
        self.fontName = fontName
        self.fontSize = fontSize
        self.isBold = isBold
        self.isItalic = isItalic
        self.isStrikethrough = isStrikethrough
        self.isUnderline = isUnderline
        self.textColor = textColor
    }
}

/// Paragraph properties parsed from header.xml.
public struct HWPXParaProperties {
    public var id: Int
    public var alignment: HWPXAlignment
    public var outlineLevel: Int?

    public init(id: Int, alignment: HWPXAlignment = .left, outlineLevel: Int? = nil) {
        self.id = id
        self.alignment = alignment
        self.outlineLevel = outlineLevel
    }
}

/// Text alignment.
public enum HWPXAlignment: String {
    case left = "LEFT"
    case center = "CENTER"
    case right = "RIGHT"
    case justify = "JUSTIFY"
    case distribute = "DISTRIBUTE"
}

/// Collection of style definitions from header.xml.
public struct HWPXStyleSheet {
    public var charProperties: [Int: HWPXCharProperties]
    public var paraProperties: [Int: HWPXParaProperties]

    public init(charProperties: [Int: HWPXCharProperties] = [:], paraProperties: [Int: HWPXParaProperties] = [:]) {
        self.charProperties = charProperties
        self.paraProperties = paraProperties
    }
}
