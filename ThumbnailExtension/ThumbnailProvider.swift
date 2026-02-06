import QuickLookThumbnailing
import UIKit

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let reply = QLThumbnailReply(contextSize: request.maximumSize) { context in
            let bounds = CGRect(origin: .zero, size: request.maximumSize)
            UIColor.white.setFill()
            context.fill(bounds)

            let title = NSString(string: "Markdown")
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: max(12, request.maximumSize.height * 0.15)),
                .foregroundColor: UIColor.black
            ]
            title.draw(at: CGPoint(x: 8, y: 8), withAttributes: attrs)
            return true
        }

        handler(reply, nil)
    }
}
