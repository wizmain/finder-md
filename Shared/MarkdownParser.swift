import Foundation

struct MarkdownParser {
    func renderHTML(from markdown: String) -> String {
        // Temporary baseline until cmark-gfm integration lands.
        let escaped = markdown
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return "<pre>\(escaped)</pre>"
    }
}
