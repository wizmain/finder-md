import Foundation
import MarkdownShared

/// Main entry point for parsing HWPX files into HTML.
public struct HWPXParser {

    public init() {}

    /// Parse an HWPX file into a document model.
    public func parse(fileURL: URL) throws -> HWPXDocument {
        let archive = try HWPXArchive(fileURL: fileURL)
        return try parse(archive: archive)
    }

    /// Parse an HWPX archive into a document model.
    public func parse(archive: HWPXArchive) throws -> HWPXDocument {
        var document = HWPXDocument()

        // Parse header for styles
        if let headerData = try? archive.extractData(at: "Contents/header.xml") {
            let headerParser = HeaderParser()
            document.styles = try headerParser.parse(data: headerData)
        }

        // Find and parse all section files
        let entries = archive.listEntries()
        let sectionPaths = entries
            .filter { $0.hasPrefix("Contents/section") && $0.hasSuffix(".xml") }
            .sorted()

        let sectionParser = SectionParser()
        for path in sectionPaths {
            let sectionData = try archive.extractData(at: path)
            let elements = try sectionParser.parse(data: sectionData)

            // Apply heading info from paragraph styles
            let resolvedElements = resolveHeadings(elements, styles: document.styles)
            document.sections.append(HWPXSection(elements: resolvedElements))
        }

        // Extract images from BinData/
        // Store by both full filename (image1.png) and base name (image1)
        // because binaryItemIDRef uses the base name without extension
        let imagePaths = entries.filter { $0.hasPrefix("BinData/") && !$0.hasSuffix("/") }
        for imagePath in imagePaths {
            if let data = try? archive.extractData(at: imagePath) {
                let filename = (imagePath as NSString).lastPathComponent
                document.images[filename] = data
                let baseName = (filename as NSString).deletingPathExtension
                if baseName != filename {
                    document.images[baseName] = data
                }
            }
        }

        return document
    }

    /// Parse an HWPX file directly to HTML body string.
    public func parseToHTML(fileURL: URL) throws -> String {
        let document = try parse(fileURL: fileURL)
        let generator = HWPXHTMLGenerator()
        return generator.generateHTML(from: document)
    }

    /// Render an HWPX file to a complete, self-contained HTML document.
    public func renderToFullHTML(fileURL: URL, configuration: RenderConfiguration = .hwpxPreview) throws -> String {
        let document = try parse(fileURL: fileURL)
        let generator = HWPXHTMLGenerator()
        let htmlBody = generator.generateHTML(from: document)

        let renderer = HTMLRenderer()
        return try renderer.renderHTMLBody(htmlBody, title: document.title ?? fileURL.deletingPathExtension().lastPathComponent, configuration: configuration)
    }

    // MARK: - Heading Resolution

    /// Resolve heading status for paragraphs based on their paragraph style's outline level.
    private func resolveHeadings(_ elements: [HWPXBlockElement], styles: HWPXStyleSheet) -> [HWPXBlockElement] {
        elements.map { element in
            guard case .paragraph(var para) = element else { return element }

            if let styleRef = para.styleRef, let paraPr = styles.paraProperties[styleRef],
               let level = paraPr.outlineLevel {
                para.isHeading = true
                para.headingLevel = level + 1  // OWPML level is 0-based, HTML is 1-based
            }

            return .paragraph(para)
        }
    }
}
