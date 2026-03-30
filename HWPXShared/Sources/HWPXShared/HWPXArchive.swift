import Foundation
import ZIPFoundation

/// Reads entries from an HWPX ZIP archive without extracting to disk.
public struct HWPXArchive {
    private let archive: Archive

    public init(fileURL: URL) throws {
        do {
            self.archive = try Archive(url: fileURL, accessMode: .read)
        } catch {
            throw HWPXError.cannotOpenArchive(fileURL.path)
        }
    }

    /// Read raw data for an entry at the given path inside the archive.
    public func extractData(at path: String) throws -> Data {
        guard let entry = archive[path] else {
            throw HWPXError.entryNotFound(path)
        }
        var data = Data()
        _ = try archive.extract(entry) { chunk in
            data.append(chunk)
        }
        return data
    }

    /// Read a UTF-8 string for an entry at the given path.
    public func extractString(at path: String) throws -> String {
        let data = try extractData(at: path)
        guard let string = String(data: data, encoding: .utf8) else {
            throw HWPXError.invalidEncoding(path)
        }
        return string
    }

    /// List all entry paths in the archive.
    public func listEntries() -> [String] {
        archive.compactMap { $0.path }
    }

    /// List entry paths matching a prefix (e.g., "Contents/", "BinData/").
    public func listEntries(prefix: String) -> [String] {
        listEntries().filter { $0.hasPrefix(prefix) }
    }

    /// Read the pre-rendered preview image if it exists.
    public func previewImage() -> Data? {
        try? extractData(at: "Preview/PrvImage.png")
    }

    /// Read the plain text preview if it exists.
    public func previewText() -> String? {
        try? extractString(at: "Preview/PrvText.txt")
    }

    /// Read an image from BinData/ directory.
    public func extractImage(named filename: String) -> Data? {
        let path = filename.hasPrefix("BinData/") ? filename : "BinData/\(filename)"
        return try? extractData(at: path)
    }
}

/// Errors specific to HWPX processing.
public enum HWPXError: Error, LocalizedError {
    case cannotOpenArchive(String)
    case entryNotFound(String)
    case invalidEncoding(String)
    case parsingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .cannotOpenArchive(let path):
            return "Cannot open HWPX archive: \(path)"
        case .entryNotFound(let path):
            return "Entry not found in HWPX archive: \(path)"
        case .invalidEncoding(let path):
            return "Invalid text encoding in HWPX entry: \(path)"
        case .parsingFailed(let detail):
            return "HWPX parsing failed: \(detail)"
        }
    }
}
