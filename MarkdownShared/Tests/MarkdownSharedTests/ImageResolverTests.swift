import XCTest
@testable import MarkdownShared

final class ImageResolverTests: XCTestCase {

    var tempDir: URL!
    var resolver: ImageResolver!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageResolverTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Create a subdirectory with a test image
        let imagesDir = tempDir.appendingPathComponent("images")
        try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        // Write a tiny 1x1 PNG
        let pngData = Self.minimalPNG()
        try pngData.write(to: imagesDir.appendingPathComponent("test.png"))
        try pngData.write(to: tempDir.appendingPathComponent("root.jpg"))

        resolver = ImageResolver(baseDirectory: tempDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Path Resolution

    func testResolveRelativePath() {
        let url = resolver.resolve("images/test.png")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.lastPathComponent, "test.png")
        XCTAssertTrue(url!.path.hasPrefix(tempDir.path))
    }

    func testResolveAbsolutePathWithinBase() {
        let absolutePath = tempDir.appendingPathComponent("root.jpg").path
        let url = resolver.resolve(absolutePath)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.lastPathComponent, "root.jpg")
    }

    func testResolveRemoteURLReturnsNil() {
        let url = resolver.resolve("https://example.com/image.png")
        XCTAssertNil(url)
    }

    func testResolveHTTPURLReturnsNil() {
        let url = resolver.resolve("http://example.com/image.png")
        XCTAssertNil(url)
    }

    func testResolveDataURIReturnsNil() {
        let url = resolver.resolve("data:image/png;base64,abc123")
        XCTAssertNil(url)
    }

    // MARK: - Parent Directory Traversal (allowed, sandbox provides security)

    func testParentDirectoryTraversalAllowed() {
        let url = resolver.resolve("../sibling/image.png")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.lastPathComponent, "image.png")
    }

    func testAbsolutePathOutsideBaseAllowed() {
        let url = resolver.resolve("/tmp/image.png")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.path, "/tmp/image.png")
    }

    // MARK: - Data URI Conversion

    func testResolveToDataURI() {
        let dataURI = resolver.resolveToDataURI("images/test.png")
        XCTAssertNotNil(dataURI)
        XCTAssertTrue(dataURI!.hasPrefix("data:image/png;base64,"))
    }

    func testResolveToDataURINonexistentFile() {
        let dataURI = resolver.resolveToDataURI("missing.png")
        XCTAssertNil(dataURI)
    }

    func testResolveToDataURIRemoteURL() {
        let dataURI = resolver.resolveToDataURI("https://example.com/img.png")
        XCTAssertNil(dataURI)
    }

    // MARK: - HTML Image Replacement

    func testResolveImagesInHTMLWithFileURLs() {
        let html = #"<p><img src="images/test.png" alt="Test"></p>"#
        let result = resolver.resolveImagesInHTML(html, embedImages: false)
        XCTAssertTrue(result.contains("file://"))
        XCTAssertTrue(result.contains("test.png"))
    }

    func testResolveImagesInHTMLWithEmbedding() {
        let html = #"<p><img src="images/test.png" alt="Test"></p>"#
        let result = resolver.resolveImagesInHTML(html, embedImages: true)
        XCTAssertTrue(result.contains("data:image/png;base64,"))
    }

    func testResolveImagesSkipsRemoteURLs() {
        let html = #"<img src="https://example.com/img.png" alt="Remote">"#
        let result = resolver.resolveImagesInHTML(html, embedImages: true)
        // Remote URLs should be left untouched
        XCTAssertTrue(result.contains("https://example.com/img.png"))
    }

    func testResolveImagesHandlesParentTraversal() {
        let html = #"<img src="../images/graph.png" alt="graph">"#
        let result = resolver.resolveImagesInHTML(html, embedImages: false)
        // Parent traversal is resolved to file:// URL
        XCTAssertTrue(result.contains("file://"))
        XCTAssertTrue(result.contains("graph.png"))
    }

    func testResolveMultipleImages() {
        let html = """
        <img src="images/test.png" alt="1">
        <img src="root.jpg" alt="2">
        """
        let result = resolver.resolveImagesInHTML(html, embedImages: false)
        XCTAssertTrue(result.contains("file://"))
        XCTAssertFalse(result.contains(#"src="images/test.png""#))
        XCTAssertFalse(result.contains(#"src="root.jpg""#))
    }

    // MARK: - MIME Type

    func testMIMETypes() {
        XCTAssertEqual(ImageResolver.mimeType(for: "png"), "image/png")
        XCTAssertEqual(ImageResolver.mimeType(for: "jpg"), "image/jpeg")
        XCTAssertEqual(ImageResolver.mimeType(for: "jpeg"), "image/jpeg")
        XCTAssertEqual(ImageResolver.mimeType(for: "gif"), "image/gif")
        XCTAssertEqual(ImageResolver.mimeType(for: "svg"), "image/svg+xml")
        XCTAssertEqual(ImageResolver.mimeType(for: "webp"), "image/webp")
        XCTAssertEqual(ImageResolver.mimeType(for: "PNG"), "image/png")
        XCTAssertEqual(ImageResolver.mimeType(for: "unknown"), "application/octet-stream")
    }

    // MARK: - Helpers

    /// Creates minimal valid PNG data (1x1 pixel, transparent).
    static func minimalPNG() -> Data {
        // Minimal 1x1 transparent PNG
        let bytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
            0x89,
            0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
            0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00,
            0x01, 0xE5, 0x27, 0xDE, 0xFC,
            0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND chunk
            0xAE, 0x42, 0x60, 0x82
        ]
        return Data(bytes)
    }
}
