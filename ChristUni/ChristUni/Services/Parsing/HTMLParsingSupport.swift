import Foundation

enum HTMLParsingSupport {
    static func stripTags(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1,
              let outputRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[outputRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func allMatches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        return matches.compactMap { match in
            guard match.numberOfRanges > 1, let valueRange = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func firstDouble(in text: String) -> Double? {
        guard let raw = firstMatch(in: text, pattern: "([0-9]+(?:\\.[0-9]+)?)") else { return nil }
        return Double(raw)
    }
}
