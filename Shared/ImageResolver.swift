import Foundation

enum ImageResolverError: Error {
    case unsupportedPath
    case directoryTraversalBlocked
}

struct ImageResolver {
    func resolveImageURL(path: String, baseDirectory: URL) throws -> URL {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            throw ImageResolverError.unsupportedPath
        }

        let candidate: URL
        if path.hasPrefix("/") {
            candidate = URL(fileURLWithPath: path)
        } else {
            candidate = baseDirectory.appendingPathComponent(path)
        }

        let normalized = candidate.standardizedFileURL
        let base = baseDirectory.standardizedFileURL

        guard normalized.path.hasPrefix(base.path) || path.hasPrefix("/") else {
            throw ImageResolverError.directoryTraversalBlocked
        }

        return normalized
    }
}
