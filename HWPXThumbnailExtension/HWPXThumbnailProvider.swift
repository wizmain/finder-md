import QuickLookThumbnailing
import AppKit
import MarkdownShared
import HWPXShared

final class HWPXThumbnailProvider: QLThumbnailProvider {

    /// App Group suite name (must match FinderMD companion app).
    private static let suiteName = "group.com.findermd.shared"

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let fileURL = request.fileURL
        let size = request.maximumSize

        // Try to use the pre-rendered preview image from the HWPX archive
        if let thumbnailReply = Self.replyFromPreviewImage(fileURL: fileURL, size: size) {
            handler(thumbnailReply, nil)
            return
        }

        // Fallback: extract text and draw thumbnail like the Markdown extension
        let (title, bodyText) = Self.extractTextPreview(fileURL: fileURL)
        let isDark = Self.resolveIsDark()

        let reply = QLThumbnailReply(contextSize: size) { context in
            Self.draw(in: context, size: size, title: title, body: bodyText, isDark: isDark)
        }

        handler(reply, nil)
    }

    // MARK: - Preview Image Strategy

    private static func replyFromPreviewImage(fileURL: URL, size: CGSize) -> QLThumbnailReply? {
        guard let archive = try? HWPXArchive(fileURL: fileURL),
              let imageData = archive.previewImage(),
              let image = NSImage(data: imageData) else {
            return nil
        }

        return QLThumbnailReply(contextSize: size) { context in
            let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = nsContext

            // White background
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            // Aspect-fit the preview image centered in the thumbnail
            let imageSize = image.size
            let scaleX = size.width / imageSize.width
            let scaleY = size.height / imageSize.height
            let scale = min(scaleX, scaleY)
            let drawWidth = imageSize.width * scale
            let drawHeight = imageSize.height * scale
            let drawRect = CGRect(
                x: (size.width - drawWidth) / 2,
                y: (size.height - drawHeight) / 2,
                width: drawWidth,
                height: drawHeight
            )
            image.draw(in: drawRect, from: .zero, operation: .copy, fraction: 1.0)
            return true
        }
    }

    // MARK: - Text Extraction Fallback

    private static func extractTextPreview(fileURL: URL) -> (title: String, body: String) {
        let fallbackTitle = fileURL.deletingPathExtension().lastPathComponent

        guard let archive = try? HWPXArchive(fileURL: fileURL) else {
            return (fallbackTitle, "")
        }

        // Try Preview/PrvText.txt first (fastest)
        if let previewText = archive.previewText(), !previewText.isEmpty {
            let lines = previewText.components(separatedBy: .newlines)
            let title = lines.first ?? fallbackTitle
            let body = lines.dropFirst().joined(separator: "\n")
            return (title, body)
        }

        // Parse first section for text
        let parser = HWPXParser()
        guard let document = try? parser.parse(archive: archive) else {
            return (fallbackTitle, "")
        }

        let title = document.title ?? fallbackTitle
        let body = document.plainText
        return (title, String(body.prefix(2000)))
    }

    // MARK: - Drawing

    private static func draw(
        in context: CGContext,
        size: CGSize,
        title: String,
        body: String,
        isDark: Bool
    ) -> Bool {
        context.saveGState()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
        NSGraphicsContext.current = nsContext

        let bgColor: NSColor
        let titleColor: NSColor
        let bodyColor: NSColor
        let separatorColor: NSColor
        let badgeColor: NSColor

        if isDark {
            bgColor        = NSColor(srgbRed: 0.051, green: 0.067, blue: 0.090, alpha: 1)
            titleColor     = NSColor(srgbRed: 0.902, green: 0.929, blue: 0.953, alpha: 1)
            bodyColor      = NSColor(srgbRed: 0.545, green: 0.580, blue: 0.620, alpha: 1)
            separatorColor = NSColor(srgbRed: 0.129, green: 0.149, blue: 0.176, alpha: 1)
            badgeColor     = NSColor(srgbRed: 0.345, green: 0.392, blue: 0.455, alpha: 1)
        } else {
            bgColor        = NSColor.white
            titleColor     = NSColor(srgbRed: 0.122, green: 0.137, blue: 0.157, alpha: 1)
            bodyColor      = NSColor(srgbRed: 0.396, green: 0.427, blue: 0.463, alpha: 1)
            separatorColor = NSColor(srgbRed: 0.816, green: 0.843, blue: 0.871, alpha: 1)
            badgeColor     = NSColor(srgbRed: 0.545, green: 0.580, blue: 0.620, alpha: 1)
        }

        let padding = max(6, size.width * 0.06)
        let contentWidth = size.width - padding * 2

        // Background
        bgColor.setFill()
        NSBezierPath.fill(CGRect(origin: .zero, size: size))

        // "HWP" badge (top-right corner)
        let badgeFontSize = max(6, min(size.height * 0.06, 10))
        let badgeFont = NSFont.systemFont(ofSize: badgeFontSize, weight: .semibold)
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: badgeColor,
        ]
        let badgeStr = NSAttributedString(string: "HWP", attributes: badgeAttrs)
        let badgeSize = badgeStr.size()
        let badgeOrigin = CGPoint(x: size.width - padding - badgeSize.width, y: padding * 0.7)
        badgeStr.draw(at: badgeOrigin)

        var yOffset = padding

        // Title
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
        let titleRect = CGRect(x: padding, y: yOffset, width: contentWidth, height: titleHeight)
        let titleAttrStr = NSAttributedString(string: title, attributes: titleAttrs)
        titleAttrStr.draw(with: titleRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        yOffset += titleHeight + padding * 0.4

        // Separator
        separatorColor.setStroke()
        let line = NSBezierPath()
        line.move(to: CGPoint(x: padding, y: yOffset))
        line.line(to: CGPoint(x: size.width - padding, y: yOffset))
        line.lineWidth = max(0.5, size.height * 0.003)
        line.stroke()

        yOffset += padding * 0.5

        // Body text
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
        let bodyRect = CGRect(
            x: padding,
            y: yOffset,
            width: contentWidth,
            height: size.height - yOffset - padding
        )
        let bodyAttrStr = NSAttributedString(string: body, attributes: bodyAttrs)
        bodyAttrStr.draw(with: bodyRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        context.restoreGState()
        return true
    }

    // MARK: - Helpers

    private static func resolveIsDark() -> Bool {
        let defaults = UserDefaults(suiteName: suiteName)
        if let raw = defaults?.string(forKey: "selectedTheme"),
           let theme = Theme(rawValue: raw) {
            return theme.isDark
        }
        return ThemeManager.systemIsDarkMode
    }
}
