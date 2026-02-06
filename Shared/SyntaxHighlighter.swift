import Foundation

enum SyntaxLanguage: String, CaseIterable {
    case swift
    case python
    case javascript
    case typescript
    case go
    case rust
    case kotlin
    case java
    case c
    case cpp
    case csharp
    case ruby
    case php
    case scala
    case lua
    case bash
    case json
    case yaml
    case html
    case css
}

struct SyntaxHighlighter {
    func highlight(code: String, language: SyntaxLanguage?) -> String {
        // Placeholder implementation. Real highlighting will be injected with bundled JS/CSS.
        let escaped = code
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return "<pre><code>\(escaped)</code></pre>"
    }
}
