import Foundation

struct HomePageData {
    var name: String?
    var classLabel: String?
    var mobileNumber: String?
    var personalEmail: String?
    var programTitle: String?
    var profilePhotoURL: String?
}

struct HomeHTMLParser {
    func parse(_ html: String) -> HomePageData {
        var output = HomePageData()
        output.name = HTMLParsingSupport.stripTags(
            HTMLParsingSupport.firstMatch(in: html, pattern: "<span\\s+class=\"name\">(.*?)</span>") ?? ""
        )
        output.classLabel = HTMLParsingSupport.stripTags(
            HTMLParsingSupport.firstMatch(in: html, pattern: "<b>\\s*Class\\s*:</b>(.*?)</div>") ?? ""
        )
        output.mobileNumber = firstNonEmpty([
            HTMLParsingSupport.firstMatch(in: html, pattern: "name=\"mobileNo\"[^>]*value=\"([^\"]+)\""),
            HTMLParsingSupport.firstMatch(in: html, pattern: "id=\"mobileNo\"[^>]*value=\"([^\"]+)\""),
            HTMLParsingSupport.stripTags(
                HTMLParsingSupport.firstMatch(in: html, pattern: "<b>\\s*Mobile\\s*No\\s*:</b>[\\s\\S]*?value=\"([^\"]+)\"") ?? ""
            ),
            HTMLParsingSupport.stripTags(
                HTMLParsingSupport.firstMatch(in: html, pattern: "Mobile\\s*No\\s*:?\\s*([^<\\n\\r]+)") ?? ""
            )
        ])

        output.personalEmail = firstNonEmpty([
            HTMLParsingSupport.firstMatch(in: html, pattern: "name=\"contactMail\"[^>]*value=\"([^\"]+)\""),
            HTMLParsingSupport.firstMatch(in: html, pattern: "id=\"contactMail\"[^>]*value=\"([^\"]+)\""),
            HTMLParsingSupport.stripTags(
                HTMLParsingSupport.firstMatch(in: html, pattern: "<b>\\s*Personal\\s*Email\\s*ID\\s*:</b>[\\s\\S]*?value=\"([^\"]+)\"") ?? ""
            ),
            HTMLParsingSupport.stripTags(
                HTMLParsingSupport.firstMatch(in: html, pattern: "Personal\\s*Email\\s*ID\\s*:?\\s*([^<\\n\\r]+)") ?? ""
            )
        ])
        output.programTitle = HTMLParsingSupport.stripTags(
            HTMLParsingSupport.firstMatch(in: html, pattern: "<b>\\s*(?:Course|Programme|Program)\\s*:</b>(.*?)</div>") ?? ""
        )

        if let imagePath = firstNonEmpty([
            HTMLParsingSupport.firstMatch(
                in: html,
                pattern: "<div\\s+class=\"prohead\">\\s*<img[^>]+src=\"([^\"]+)\""
            ),
            HTMLParsingSupport.firstMatch(
                in: html,
                pattern: "class=\"prohead\"[\\s\\S]*?<img[^>]+src=\"([^\"]+)\""
            )
        ]) {
            output.profilePhotoURL = normalizePhotoURL(imagePath)
        }

        return output
    }

    private func normalizePhotoURL(_ path: String) -> String? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()
        if lowered.contains("questionmark.jpg") {
            return nil
        }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        let base = "https://kp.christuniversity.in/KnowledgePro/"
        if trimmed.hasPrefix("/") {
            return "https://kp.christuniversity.in\(trimmed)"
        }
        if trimmed.hasPrefix("./") {
            return base + String(trimmed.dropFirst(2))
        }
        if trimmed.hasPrefix("../") {
            return "https://kp.christuniversity.in/" + String(trimmed.dropFirst(3))
        }
        return base + trimmed
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && $0 != ":" && $0 != "-" }
    }
}
