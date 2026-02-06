import Foundation

struct MarkdownRenderer {
    private let parser = MarkdownParser()

    func render(markdown: String, sourceURL: URL) throws -> String {
        let content = parser.renderHTML(from: markdown)
        let templateURL = Bundle.main.url(forResource: "template", withExtension: "html")

        guard let templateURL,
              let template = try? String(contentsOf: templateURL, encoding: .utf8) else {
            return content
        }

        return template.replacingOccurrences(of: "{{content}}", with: content)
    }
}
