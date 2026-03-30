import Foundation

/// Converts an HWPXDocument model into an HTML body string.
public struct HWPXHTMLGenerator {

    public init() {}

    /// Generate HTML body from an HWPX document.
    public func generateHTML(from document: HWPXDocument) -> String {
        var html = ""
        for section in document.sections {
            for element in section.elements {
                html += renderElement(element, styles: document.styles, images: document.images)
            }
        }
        return html
    }

    // MARK: - Element Rendering

    private func renderElement(_ element: HWPXBlockElement, styles: HWPXStyleSheet, images: [String: Data]) -> String {
        switch element {
        case .paragraph(let para):
            return renderParagraph(para, styles: styles, images: images)
        case .table(let table):
            return renderTable(table, styles: styles, images: images)
        }
    }

    private func renderParagraph(_ para: HWPXParagraph, styles: HWPXStyleSheet, images: [String: Data]) -> String {
        if para.isEmpty && !para.isHeading { return "" }

        let content = para.runs.map { renderRun($0, styles: styles, images: images) }.joined()
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !para.isHeading {
            return "<br>\n"
        }

        // Determine alignment from paragraph style
        let alignStyle: String
        if let styleRef = para.styleRef, let paraPr = styles.paraProperties[styleRef] {
            alignStyle = alignmentCSS(paraPr.alignment)
        } else {
            alignStyle = ""
        }

        let styleAttr = alignStyle.isEmpty ? "" : " style=\"\(alignStyle)\""

        if para.isHeading {
            let level = min(max(para.headingLevel, 1), 6)
            return "<h\(level)\(styleAttr)>\(content)</h\(level)>\n"
        }

        return "<p\(styleAttr)>\(content)</p>\n"
    }

    private func renderRun(_ run: HWPXRun, styles: HWPXStyleSheet, images: [String: Data]) -> String {
        // Image run
        if let imageRef = run.imageRef {
            return renderImage(imageRef, images: images)
        }

        let text = escapeHTML(run.text)
        if text.isEmpty { return "" }

        // Apply character styling
        guard let charRef = run.charStyleRef, let charPr = styles.charProperties[charRef] else {
            return text
        }

        var result = text

        if charPr.isBold { result = "<strong>\(result)</strong>" }
        if charPr.isItalic { result = "<em>\(result)</em>" }
        if charPr.isStrikethrough { result = "<del>\(result)</del>" }
        if charPr.isUnderline { result = "<u>\(result)</u>" }

        // Inline styles for font/color
        var inlineStyles: [String] = []
        if let color = charPr.textColor, color != "#000000" && color != "000000" {
            let cssColor = color.hasPrefix("#") ? color : "#\(color)"
            inlineStyles.append("color:\(cssColor)")
        }
        if let size = charPr.fontSize, size != 10.0 {
            inlineStyles.append("font-size:\(size)pt")
        }
        if let font = charPr.fontName {
            inlineStyles.append("font-family:'\(font)'")
        }

        if !inlineStyles.isEmpty {
            result = "<span style=\"\(inlineStyles.joined(separator: ";"))\">\(result)</span>"
        }

        return result
    }

    private func renderImage(_ ref: String, images: [String: Data]) -> String {
        let filename = ref.hasPrefix("BinData/") ? String(ref.dropFirst("BinData/".count)) : ref
        if let data = images[filename] ?? images[ref] {
            let mime = mimeType(for: filename, data: data)
            let base64 = data.base64EncodedString()
            return "<img src=\"data:\(mime);base64,\(base64)\" style=\"max-width:100%;height:auto;\">\n"
        }
        return "<p>[Image: \(escapeHTML(filename))]</p>\n"
    }

    private func renderTable(_ table: HWPXTable, styles: HWPXStyleSheet, images: [String: Data]) -> String {
        var html = "<table style=\"border-collapse:collapse;width:100%;margin:1em 0;\">\n"
        for row in table.rows {
            html += "<tr>\n"
            for cell in row.cells {
                let spanAttrs = [
                    cell.colSpan > 1 ? " colspan=\"\(cell.colSpan)\"" : "",
                    cell.rowSpan > 1 ? " rowspan=\"\(cell.rowSpan)\"" : ""
                ].joined()
                let cellContent = cell.paragraphs.map { renderParagraph($0, styles: styles, images: images) }.joined()
                html += "<td\(spanAttrs) style=\"border:1px solid #ddd;padding:8px;\">\(cellContent)</td>\n"
            }
            html += "</tr>\n"
        }
        html += "</table>\n"
        return html
    }

    // MARK: - Utilities

    private func alignmentCSS(_ alignment: HWPXAlignment) -> String {
        switch alignment {
        case .left: return ""
        case .center: return "text-align:center"
        case .right: return "text-align:right"
        case .justify, .distribute: return "text-align:justify"
        }
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private func mimeType(for filename: String, data: Data? = nil) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        if !ext.isEmpty {
            switch ext {
            case "png": return "image/png"
            case "jpg", "jpeg": return "image/jpeg"
            case "gif": return "image/gif"
            case "bmp": return "image/bmp"
            case "svg": return "image/svg+xml"
            case "webp": return "image/webp"
            case "tiff", "tif": return "image/tiff"
            default: return "image/png"
            }
        }
        // No extension — detect from magic bytes
        if let data = data, data.count >= 4 {
            let bytes = [UInt8](data.prefix(4))
            if bytes[0] == 0x89 && bytes[1] == 0x50 { return "image/png" }
            if bytes[0] == 0xFF && bytes[1] == 0xD8 { return "image/jpeg" }
            if bytes[0] == 0x47 && bytes[1] == 0x49 { return "image/gif" }
            if bytes[0] == 0x42 && bytes[1] == 0x4D { return "image/bmp" }
        }
        return "image/png"
    }
}
