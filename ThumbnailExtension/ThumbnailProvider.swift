import QuickLookThumbnailing
import AppKit
import MarkdownShared

final class ThumbnailProvider: QLThumbnailProvider {

    private let parser = MarkdownParser()

    /// Maximum bytes to read from file for thumbnail generation (performance).
    private static let maxReadBytes = 4096

    /// App Group suite name (must match FinderMD companion app).
    private static let suiteName = "group.com.findermd.shared"

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let fileURL = request.fileURL
        let size = request.maximumSize

        // Read only the beginning of the file for fast thumbnail generation
        guard let markdown = Self.readHead(of: fileURL) else {
            handler(nil, nil)
            return
        }

        let parsed = parser.parse(markdown)
        let title = parsed.title
            ?? parsed.frontmatter["title"]
            ?? fileURL.deletingPathExtension().lastPathComponent
        let bodyText = Self.stripHTMLTags(from: parsed.html)
        let isDark = Self.resolveIsDark()

        let reply = QLThumbnailReply(contextSize: size, currentContextDrawing: {
            Self.draw(
                size: size,
                title: title,
                body: bodyText,
                isDark: isDark
            )
        })

        handler(reply, nil)
    }

    // MARK: - Drawing

    private static func draw(
        size: CGSize,
        title: String,
        body: String,
        isDark: Bool
    ) -> Bool {
        guard NSGraphicsContext.current != nil else { return false }

        // Theme colors (GitHub Light / GitHub Dark)
        let bgColor: NSColor
        let titleColor: NSColor
        let bodyColor: NSColor
        let separatorColor: NSColor
        let badgeColor: NSColor

        if isDark {
            bgColor        = NSColor(srgbRed: 0.051, green: 0.067, blue: 0.090, alpha: 1) // #0d1117
            titleColor     = NSColor(srgbRed: 0.902, green: 0.929, blue: 0.953, alpha: 1) // #e6edf3
            bodyColor      = NSColor(srgbRed: 0.545, green: 0.580, blue: 0.620, alpha: 1) // #8b949e
            separatorColor = NSColor(srgbRed: 0.129, green: 0.149, blue: 0.176, alpha: 1) // #21262d
            badgeColor     = NSColor(srgbRed: 0.345, green: 0.392, blue: 0.455, alpha: 1) // #586473
        } else {
            bgColor        = NSColor.white
            titleColor     = NSColor(srgbRed: 0.122, green: 0.137, blue: 0.157, alpha: 1) // #1F2328
            bodyColor      = NSColor(srgbRed: 0.396, green: 0.427, blue: 0.463, alpha: 1) // #656d76
            separatorColor = NSColor(srgbRed: 0.816, green: 0.843, blue: 0.871, alpha: 1) // #d0d7de
            badgeColor     = NSColor(srgbRed: 0.545, green: 0.580, blue: 0.620, alpha: 1) // #8b949e
        }

        let padding = max(6, size.width * 0.06)
        let contentWidth = size.width - padding * 2

        // Background
        bgColor.setFill()
        NSBezierPath.fill(CGRect(origin: .zero, size: size))

        // "MD" badge (top-right corner)
        let badgeFontSize = max(6, min(size.height * 0.06, 10))
        let badgeFont = NSFont.systemFont(ofSize: badgeFontSize, weight: .semibold)
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: badgeColor,
        ]
        let badgeStr = NSAttributedString(string: "MD", attributes: badgeAttrs)
        let badgeSize = badgeStr.size()
        let badgeOrigin = CGPoint(
            x: size.width - padding - badgeSize.width,
            y: size.height - (padding * 0.7) - badgeSize.height
        )
        badgeStr.draw(at: badgeOrigin)

        var yOffset = padding

        // Title (up to 2 lines)
        let titleFontSize = max(9, min(size.height * 0.08, 16))
        let titleFont = NSFont.boldSystemFont(ofSize: titleFontSize)
        let titleParagraph = NSMutableParagraphStyle()
        titleParagraph.lineBreakMode = .byTruncatingTail
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: titleColor,
            .paragraphStyle: titleParagraph,
        ]
        let titleHeight = titleFontSize * 2.6
        let titleRect = rectFromTop(
            x: padding,
            y: yOffset,
            width: contentWidth,
            height: titleHeight,
            canvasHeight: size.height
        )
        let titleAttrStr = NSAttributedString(string: title, attributes: titleAttrs)
        titleAttrStr.draw(with: titleRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        yOffset += titleHeight + padding * 0.4

        // Separator line
        separatorColor.setStroke()
        let line = NSBezierPath()
        let lineY = size.height - yOffset
        line.move(to: CGPoint(x: padding, y: lineY))
        line.line(to: CGPoint(x: size.width - padding, y: lineY))
        line.lineWidth = max(0.5, size.height * 0.003)
        line.stroke()

        yOffset += padding * 0.5

        // Body text (fills remaining space)
        let bodyFontSize = max(6, min(size.height * 0.05, 11))
        let bodyFont = NSFont.systemFont(ofSize: bodyFontSize)
        let bodyParagraph = NSMutableParagraphStyle()
        bodyParagraph.lineBreakMode = .byWordWrapping
        bodyParagraph.lineSpacing = bodyFontSize * 0.15
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: bodyColor,
            .paragraphStyle: bodyParagraph,
        ]
        let bodyRect = rectFromTop(
            x: padding,
            y: yOffset,
            width: contentWidth,
            height: size.height - yOffset - padding,
            canvasHeight: size.height
        )
        let bodyAttrStr = NSAttributedString(string: body, attributes: bodyAttrs)
        bodyAttrStr.draw(with: bodyRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        return true
    }

    // MARK: - Helpers

    /// Read only the first few KB of a file for fast parsing.
    private static func readHead(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: maxReadBytes) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Determine dark mode: prefer user theme setting, fallback to system.
    private static func resolveIsDark() -> Bool {
        let defaults = UserDefaults(suiteName: suiteName)
        if let raw = defaults?.string(forKey: "selectedTheme"),
           let theme = Theme(rawValue: raw) {
            return theme.isDark
        }
        return ThemeManager.systemIsDarkMode
    }

    /// Strip HTML tags and decode entities to produce plain text.
    private static func stripHTMLTags(from html: String) -> String {
        var text = html
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func rectFromTop(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        canvasHeight: CGFloat
    ) -> CGRect {
        CGRect(x: x, y: canvasHeight - y - height, width: width, height: height)
    }
}
