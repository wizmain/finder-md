import Quartz
import UniformTypeIdentifiers
import MarkdownShared

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {

    private let renderer = HTMLRenderer()

    /// App Group suite name (must match FinderMD companion app).
    private static let suiteName = "group.com.findermd.shared"

    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        let configuration = Self.loadConfiguration()
        do {
            let html = try renderer.render(fileURL: request.fileURL, configuration: configuration)
            let data = Data(html.utf8)
            let reply = QLPreviewReply(dataOfContentType: UTType.html, contentSize: CGSize(width: 800, height: 1200)) { _ in
                return data
            }
            reply.stringEncoding = String.Encoding.utf8
            reply.title = request.fileURL.deletingPathExtension().lastPathComponent
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }

    /// Read user preferences from shared App Group UserDefaults.
    private static func loadConfiguration() -> RenderConfiguration {
        var config = RenderConfiguration.quickLook
        let defaults = UserDefaults(suiteName: suiteName)
        if let raw = defaults?.string(forKey: "selectedTheme"),
           let theme = Theme(rawValue: raw) {
            config.theme = theme
        }
        return config
    }
}
