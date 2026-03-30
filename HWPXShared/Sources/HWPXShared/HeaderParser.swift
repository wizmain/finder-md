import Foundation

/// Parses HWPX header.xml for style definitions (character properties, paragraph properties, fonts).
public final class HeaderParser: NSObject {

    private var charProperties: [Int: HWPXCharProperties] = [:]
    private var paraProperties: [Int: HWPXParaProperties] = [:]
    private var fontMap: [Int: String] = [:]  // font ID → face name (HANGUL preferred)

    // Parser state
    private var currentCharPr: HWPXCharProperties?
    private var currentParaPr: HWPXParaProperties?
    private var currentFontFaceLang: String?
    private var parserError: Error?

    /// Parse header XML string into a style sheet.
    public func parse(xml: String) throws -> HWPXStyleSheet {
        let data = Data(xml.utf8)
        return try parse(data: data)
    }

    /// Parse header XML data into a style sheet.
    public func parse(data: Data) throws -> HWPXStyleSheet {
        charProperties = [:]
        paraProperties = [:]
        fontMap = [:]
        currentCharPr = nil
        currentParaPr = nil
        currentFontFaceLang = nil
        parserError = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.shouldReportNamespacePrefixes = false

        guard parser.parse() else {
            if let error = parserError {
                throw error
            }
            throw HWPXError.parsingFailed("Header XML parsing failed")
        }

        // Resolve font ID references in charProperties to actual font names
        for (id, var charPr) in charProperties {
            if let fontName = charPr.fontName, let fontId = Int(fontName) {
                charPr.fontName = fontMap[fontId] ?? fontName
                charProperties[id] = charPr
            }
        }

        return HWPXStyleSheet(charProperties: charProperties, paraProperties: paraProperties)
    }

    private func localName(from qualifiedName: String) -> String {
        if let colonIndex = qualifiedName.firstIndex(of: ":") {
            return String(qualifiedName[qualifiedName.index(after: colonIndex)...])
        }
        return qualifiedName
    }

    /// Convert HWPUNIT to points (100 HWPUNIT = 1pt).
    private func hwpunitToPoints(_ value: String) -> Double? {
        guard let intValue = Int(value) else { return nil }
        return Double(intValue) / 100.0
    }
}

// MARK: - XMLParserDelegate

extension HeaderParser: XMLParserDelegate {

    public func parser(_ parser: XMLParser, didStartElement elementName: String,
                       namespaceURI: String?, qualifiedName qName: String?,
                       attributes: [String: String] = [:]) {
        let local = localName(from: qName ?? elementName)

        switch local {
        case "charPr":
            if let idStr = attributes["id"], let id = Int(idStr) {
                var charPr = HWPXCharProperties(id: id)
                if let height = attributes["height"] {
                    charPr.fontSize = hwpunitToPoints(height)
                }
                if let color = attributes["textColor"] {
                    charPr.textColor = color
                }
                currentCharPr = charPr
            }

        case "bold":
            currentCharPr?.isBold = true

        case "italic":
            currentCharPr?.isItalic = true

        case "strikeout", "strikethrough":
            // Only actual strikethrough shapes count — NONE and 3D are not strikethrough
            let shape = attributes["shape"] ?? "NONE"
            if shape != "NONE" && shape != "3D" {
                currentCharPr?.isStrikethrough = true
            }

        case "underline":
            currentCharPr?.isUnderline = true

        case "fontRef":
            if let face = attributes["hangul"] ?? attributes["latin"] {
                currentCharPr?.fontName = face
            }

        case "fontface":
            currentFontFaceLang = attributes["lang"]

        case "font":
            // Build font ID → face name map. Prefer HANGUL, then LATIN.
            if let idStr = attributes["id"], let id = Int(idStr), let face = attributes["face"] {
                if currentFontFaceLang == "HANGUL" || fontMap[id] == nil {
                    fontMap[id] = face
                }
            }

        case "paraPr":
            if let idStr = attributes["id"], let id = Int(idStr) {
                let alignment: HWPXAlignment
                if let align = attributes["align"] {
                    alignment = HWPXAlignment(rawValue: align) ?? .left
                } else {
                    alignment = .left
                }
                currentParaPr = HWPXParaProperties(id: id, alignment: alignment)
            }

        case "heading":
            // Only type="OUTLINE" is an actual heading.
            // NONE, BULLET, NUMBER are not headings.
            let headingType = attributes["type"] ?? "NONE"
            if headingType == "OUTLINE",
               let levelStr = attributes["level"], let level = Int(levelStr) {
                currentParaPr?.outlineLevel = level
            }

        case "outline":
            if let levelStr = attributes["level"], let level = Int(levelStr) {
                currentParaPr?.outlineLevel = level
            }

        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String,
                       namespaceURI: String?, qualifiedName qName: String?) {
        let local = localName(from: qName ?? elementName)

        switch local {
        case "charPr":
            if let charPr = currentCharPr {
                charProperties[charPr.id] = charPr
            }
            currentCharPr = nil

        case "paraPr":
            if let paraPr = currentParaPr {
                paraProperties[paraPr.id] = paraPr
            }
            currentParaPr = nil

        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parserError = parseError
    }
}
