import Foundation
import Markdown

// MARK: - ParsedMarkdown

/// Result of parsing a Markdown document.
public struct ParsedMarkdown: Sendable {
    /// Rendered HTML body (inner content, not a full document).
    public let html: String
    /// Document title extracted from the first H1 heading.
    public let title: String?
    /// YAML frontmatter key-value pairs (if present).
    public let frontmatter: [String: String]
    /// Image source paths found in the document.
    public let imageSources: [String]
}

// MARK: - MarkdownParser

/// Parses Markdown text into HTML and extracts metadata.
public struct MarkdownParser {

    public init() {}

    /// Parse Markdown text into structured result with HTML and metadata.
    public func parse(_ markdown: String) -> ParsedMarkdown {
        let (body, frontmatter) = extractFrontmatter(from: markdown)
        let document = Document(parsing: body, options: [.parseBlockDirectives])
        let html = HTMLFormatter.format(document)
        let title = extractTitle(from: document)
        let imageSources = extractImageSources(from: document)

        return ParsedMarkdown(
            html: html,
            title: title,
            frontmatter: frontmatter,
            imageSources: imageSources
        )
    }

    /// Convenience: parse Markdown and return only the HTML string.
    public func parseToHTML(_ markdown: String) -> String {
        return parse(markdown).html
    }

    // MARK: - Frontmatter Extraction

    /// Extracts YAML frontmatter delimited by `---` at the start of the document.
    /// Returns the body without frontmatter and a dictionary of key-value pairs.
    private func extractFrontmatter(from markdown: String) -> (body: String, frontmatter: [String: String]) {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("---") else {
            return (markdown, [:])
        }

        let lines = markdown.components(separatedBy: "\n")
        guard let firstDashIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            return (markdown, [:])
        }

        // Find the closing ---
        let searchStart = lines.index(after: firstDashIndex)
        guard searchStart < lines.endIndex else {
            return (markdown, [:])
        }

        var closingIndex: Int?
        for i in searchStart..<lines.endIndex {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
        }

        guard let endIndex = closingIndex else {
            return (markdown, [:])
        }

        // Parse simple key: value pairs from frontmatter
        var frontmatter: [String: String] = [:]
        for i in (firstDashIndex + 1)..<endIndex {
            let line = lines[i]
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    frontmatter[key] = value
                }
            }
        }

        // Reconstruct body without frontmatter
        let bodyLines = Array(lines[(endIndex + 1)...])
        let body = bodyLines.joined(separator: "\n")

        return (body, frontmatter)
    }

    // MARK: - Title Extraction

    /// Walks the AST to find the first H1 heading and extracts its plain text.
    private func extractTitle(from document: Document) -> String? {
        var walker = TitleWalker()
        walker.visit(document)
        return walker.title
    }

    // MARK: - Image Source Extraction

    /// Walks the AST to collect all image source URLs.
    private func extractImageSources(from document: Document) -> [String] {
        var walker = ImageWalker()
        walker.visit(document)
        return walker.sources
    }
}

// MARK: - AST Walkers

/// Walks the Markdown AST to find the first H1 heading.
private struct TitleWalker: MarkupWalker {
    var title: String?

    mutating func visitHeading(_ heading: Heading) {
        if title == nil && heading.level == 1 {
            title = heading.plainText
        }
        descendInto(heading)
    }
}

/// Walks the Markdown AST to collect image source paths.
private struct ImageWalker: MarkupWalker {
    var sources: [String] = []

    mutating func visitImage(_ image: Markdown.Image) {
        if let source = image.source {
            sources.append(source)
        }
        descendInto(image)
    }
}
