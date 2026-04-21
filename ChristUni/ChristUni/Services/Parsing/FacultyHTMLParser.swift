import Foundation

struct FacultyHTMLParser {
    struct FacultyPageData {
        let departments: [String]
        let faculty: [Faculty]
    }

    func parse(_ html: String) -> [Faculty] {
        parsePage(html).faculty
    }

    func parsePage(_ html: String) -> FacultyPageData {
        guard let rowRegex = try? NSRegularExpression(
            pattern: "<tr[^>]*>(.*?)</tr>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ), let cellRegex = try? NSRegularExpression(
            pattern: "<td[^>]*>(.*?)</td>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return FacultyPageData(departments: parseDepartments(html), faculty: [])
        }
        let fullRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let faculty: [Faculty] = rowRegex.matches(in: html, options: [], range: fullRange).compactMap { rowMatch -> Faculty? in
            guard let rowRange = Range(rowMatch.range(at: 1), in: html) else { return nil }
            let rowHTML = String(html[rowRange])
            let rowNSRange = NSRange(rowHTML.startIndex..<rowHTML.endIndex, in: rowHTML)
            let cells = cellRegex.matches(in: rowHTML, options: [], range: rowNSRange).compactMap { cellMatch -> String? in
                guard let range = Range(cellMatch.range(at: 1), in: rowHTML) else { return nil }
                return HTMLParsingSupport.stripTags(String(rowHTML[range]))
            }
            guard cells.count >= 7 else { return nil }
            // Skip header/footer rows; data rows begin with serial number.
            let serial = cells[0].trimmingCharacters(in: .whitespacesAndNewlines)
            guard Int(serial) != nil else { return nil }
            return Faculty(
                id: UUID(),
                name: cells[1],
                email: cells[2],
                department: cells[3],
                cabin: cells[4],
                campus: cells[6]
            )
        }
        return FacultyPageData(departments: parseDepartments(html), faculty: faculty)
    }

    private func parseDepartments(_ html: String) -> [String] {
        guard let inputTag = HTMLParsingSupport.firstMatch(
            in: html,
            pattern: "(<input[^>]*id=\"deptNameList\"[^>]*>)"
        ) else {
            return []
        }
        guard let rawList = HTMLParsingSupport.firstMatch(
            in: inputTag,
            pattern: "value=\"([^\"]*)\""
        ) else {
            return []
        }
        return rawList
            .replacingOccurrences(of: "&amp;", with: "&")
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
