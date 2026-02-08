import Foundation

/// Errors that can occur during image resolution.
public enum ImageResolverError: Error, Equatable {
    case directoryTraversalBlocked(String)
    case unsupportedScheme(String)
    case fileNotFound(String)
}

/// Resolves image paths relative to a base directory with security protections.
/// Supports conversion to base64 data URIs for self-contained HTML documents.
public struct ImageResolver {

    /// The base directory against which relative paths are resolved.
    public let baseDirectory: URL

    public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory.standardized
    }

    // MARK: - Path Resolution

    /// Resolves an image source path to a file URL.
    /// Returns `nil` for remote URLs (http/https) or invalid paths.
    /// Throws for directory traversal attempts.
    public func resolve(_ source: String) throws -> URL? {
        // Skip remote URLs
        if source.lowercased().hasPrefix("http://") || source.lowercased().hasPrefix("https://") {
            return nil
        }

        // Skip data URIs (already embedded)
        if source.lowercased().hasPrefix("data:") {
            return nil
        }

        let fileURL: URL
        if source.hasPrefix("/") {
            // Absolute path
            fileURL = URL(fileURLWithPath: source).standardized
        } else {
            // Relative path
            fileURL = baseDirectory.appendingPathComponent(source).standardized
        }

        // Security: prevent directory traversal
        let resolvedPath = fileURL.path
        let basePath = baseDirectory.path

        guard resolvedPath.hasPrefix(basePath) else {
            throw ImageResolverError.directoryTraversalBlocked(source)
        }

        return fileURL
    }

    // MARK: - Data URI Conversion

    /// Resolves an image source to a base64 data URI string.
    /// Returns `nil` if the file doesn't exist or is a remote URL.
    /// Throws for directory traversal attempts.
    public func resolveToDataURI(_ source: String) throws -> String? {
        guard let fileURL = try resolve(source) else {
            return nil
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        let mimeType = Self.mimeType(for: fileURL.pathExtension)
        let base64 = data.base64EncodedString()
        return "data:\(mimeType);base64,\(base64)"
    }

    // MARK: - Remote Image Download

    /// Downloads a remote image and returns a base64 data URI.
    /// Returns `nil` on failure or timeout.
    private func downloadRemoteImageAsDataURI(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }

        let ext = url.pathExtension
        let mimeType = ext.isEmpty ? "image/png" : Self.mimeType(for: ext)
        let base64 = data.base64EncodedString()
        return "data:\(mimeType);base64,\(base64)"
    }

    // MARK: - HTML Image Replacement

    /// Replaces `<img src="...">` in HTML with resolved paths or data URIs.
    /// - Parameters:
    ///   - html: The HTML content to process.
    ///   - embedImages: If `true`, replaces with base64 data URIs (including remote images). If `false`, replaces with file:// URLs.
    /// - Returns: HTML with resolved image sources.
    public func resolveImagesInHTML(_ html: String, embedImages: Bool) -> String {
        // Match <img ... src="..." ...> patterns
        guard let regex = try? NSRegularExpression(
            pattern: #"(<img\s[^>]*?src\s*=\s*")([^"]+)("[^>]*?>)"#,
            options: [.caseInsensitive]
        ) else {
            return html
        }

        let nsHTML = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        var result = html
        // Process matches in reverse order to preserve ranges
        for match in matches.reversed() {
            guard match.numberOfRanges == 4 else { continue }

            let srcRange = match.range(at: 2)
            let source = nsHTML.substring(with: srcRange)

            let replacement: String?
            if embedImages {
                let isRemote = source.lowercased().hasPrefix("http://")
                    || source.lowercased().hasPrefix("https://")
                if isRemote {
                    replacement = downloadRemoteImageAsDataURI(source)
                } else {
                    replacement = try? resolveToDataURI(source)
                }
            } else {
                replacement = (try? resolve(source))?.absoluteString
            }

            if let replacement = replacement {
                let fullRange = match.range(at: 0)
                let prefix = nsHTML.substring(with: match.range(at: 1))
                let suffix = nsHTML.substring(with: match.range(at: 3))
                let fullReplacement = prefix + replacement + suffix

                let swiftRange = Range(fullRange, in: result)!
                result.replaceSubrange(swiftRange, with: fullReplacement)
            }
        }

        return result
    }

    // MARK: - MIME Type Detection

    /// Returns the MIME type for common image file extensions.
    static func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "webp": return "image/webp"
        case "bmp": return "image/bmp"
        case "ico": return "image/x-icon"
        case "tiff", "tif": return "image/tiff"
        default: return "application/octet-stream"
        }
    }
}
