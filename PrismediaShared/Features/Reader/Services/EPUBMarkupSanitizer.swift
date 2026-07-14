import Foundation

struct EPUBMarkupSanitizer: Sendable {
    func sanitize(_ data: Data) throws -> Data {
        guard var markup = String(data: data, encoding: .utf8) else {
            throw EPUBReaderError.malformedPackageDocument
        }
        markup = markup.replacingOccurrences(
            of: #"(?is)<script\b[^>]*>.*?</script\s*>"#,
            with: "",
            options: .regularExpression
        )
        markup = markup.replacingOccurrences(
            of: #"(?i)\son[a-z]+\s*=\s*([\"']).*?\1"#,
            with: "",
            options: .regularExpression
        )
        let policy = """
            <meta http-equiv="Content-Security-Policy" content="default-src 'self' data:; script-src 'none'; object-src 'none'; connect-src 'none'; frame-src 'none'; img-src 'self' data:; font-src 'self' data:; style-src 'self' 'unsafe-inline'">
            """
        if let headStart = markup.range(of: "<head", options: .caseInsensitive),
            let headEnd = markup.range(of: ">", range: headStart.lowerBound..<markup.endIndex)
        {
            markup.insert(contentsOf: policy, at: headEnd.upperBound)
        } else if let htmlStart = markup.range(of: "<html", options: .caseInsensitive),
            let htmlEnd = markup.range(of: ">", range: htmlStart.lowerBound..<markup.endIndex)
        {
            markup.insert(contentsOf: "<head>\(policy)</head>", at: htmlEnd.upperBound)
        } else {
            markup = "<html><head>\(policy)</head><body>\(markup)</body></html>"
        }
        return Data(markup.utf8)
    }
}
