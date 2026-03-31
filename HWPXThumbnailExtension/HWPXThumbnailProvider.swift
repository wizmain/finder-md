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

    // MARK: - Preview Image Strategy

    private static func replyFromPreviewImage(fileURL: URL, size: CGSize) -> QLThumbnailReply? {
        guard let archive = try? HWPXArchive(fileURL: fileURL),
              let imageData = archive.previewImage(),
              let previewImage = NSImage(data: imageData) else {
            return nil
        }

        return QLThumbnailReply(contextSize: size, currentContextDrawing: {
            guard NSGraphicsContext.current != nil else { return false }

            let backgroundColor = NSColor.white
            let shadowColor = NSColor.black.withAlphaComponent(0.08)

            backgroundColor.setFill()
            NSBezierPath.fill(CGRect(origin: .zero, size: size))

            let outerPadding = max(8, min(size.width, size.height) * 0.08)
            let availableRect = CGRect(
                x: outerPadding,
                y: outerPadding,
                width: max(1, size.width - outerPadding * 2),
                height: max(1, size.height - outerPadding * 2)
            )

            let imageSize = previewImage.size
            guard imageSize.width > 0, imageSize.height > 0 else { return false }

            let scale = min(
                availableRect.width / imageSize.width,
                availableRect.height / imageSize.height
            )
            let drawSize = CGSize(
                width: imageSize.width * scale,
                height: imageSize.height * scale
            )
            let drawRect = CGRect(
                x: availableRect.midX - drawSize.width / 2,
                y: availableRect.midY - drawSize.height / 2,
                width: drawSize.width,
                height: drawSize.height
            )

            let shadow = NSShadow()
            shadow.shadowColor = shadowColor
            shadow.shadowBlurRadius = max(4, min(size.width, size.height) * 0.03)
            shadow.shadowOffset = CGSize(width: 0, height: -1)

            NSGraphicsContext.saveGraphicsState()
            shadow.set()
            NSColor.white.setFill()
            NSBezierPath.fill(drawRect)
            NSGraphicsContext.restoreGraphicsState()

            previewImage.draw(
                in: drawRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )

            return true
        })
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
        size: CGSize,
        title: String,
        body: String,
        isDark: Bool
    ) -> Bool {
        guard NSGraphicsContext.current != nil else { return false }

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
        let badgeOrigin = CGPoint(
            x: size.width - padding - badgeSize.width,
            y: size.height - (padding * 0.7) - badgeSize.height
        )
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

        // Separator
        separatorColor.setStroke()
        let line = NSBezierPath()
        let lineY = size.height - yOffset
        line.move(to: CGPoint(x: padding, y: lineY))
        line.line(to: CGPoint(x: size.width - padding, y: lineY))
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

    private static func resolveIsDark() -> Bool {
        let defaults = UserDefaults(suiteName: suiteName)
        if let raw = defaults?.string(forKey: "selectedTheme"),
           let theme = Theme(rawValue: raw) {
            return theme.isDark
        }
        return ThemeManager.systemIsDarkMode
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
