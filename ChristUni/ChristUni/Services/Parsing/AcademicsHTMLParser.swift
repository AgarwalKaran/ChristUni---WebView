import Foundation

struct AcademicsPageData {
    var programTitle: String?
    var currentSemesterLabel: String?
    var cumulativeGPA: Double?
    var overallPercentage: Double?
    var records: [SemesterRecord]
}

struct AcademicsExamOption {
    var examId: String
    var semesterNumber: Int
    var examLabel: String
    var displayTitle: String
}

struct AcademicsHTMLParser {
    func parseExamOptions(_ selectionHTML: String) -> [AcademicsExamOption] {
        guard let regex = try? NSRegularExpression(
            pattern: "<option\\s+value=\"([^\"]+)\">\\s*Sem:([0-9]+)-\\(([^)]+)\\)\\s*</option>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }
        let range = NSRange(selectionHTML.startIndex..<selectionHTML.endIndex, in: selectionHTML)
        let matches = regex.matches(in: selectionHTML, options: [], range: range)
        return matches.compactMap { match in
            guard
                let idRange = Range(match.range(at: 1), in: selectionHTML),
                let semRange = Range(match.range(at: 2), in: selectionHTML),
                let labelRange = Range(match.range(at: 3), in: selectionHTML)
            else { return nil }
            let examId = String(selectionHTML[idRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let semNo = Int(String(selectionHTML[semRange])) ?? 0
            let label = HTMLParsingSupport.stripTags(String(selectionHTML[labelRange]))
            guard !examId.isEmpty, semNo > 0 else { return nil }
            return AcademicsExamOption(
                examId: examId,
                semesterNumber: semNo,
                examLabel: label,
                displayTitle: "Semester \(semNo)"
            )
        }
    }

    func parseSemesterResult(resultHTML: String, option: AcademicsExamOption) -> SemesterRecord? {
        let gpa = HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(
                in: resultHTML,
                pattern: "Grade\\s*Points\\s*Average\\s*:\\s*<span[^>]*>([0-9.]+)"
            ) ?? ""
        )

        let maxMarks = HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(
                in: resultHTML,
                pattern: "Total\\s*Marks\\s*\\(In\\s*Words\\)[\\s\\S]*?<b\\s+class=\"text-danger\">\\s*([0-9.]+)\\s*</b>\\s*</td>\\s*<td\\s+align=\"center\">\\s*<b\\s+class=\"text-danger\">"
            ) ?? ""
        )
        let earnedMarks = HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(
                in: resultHTML,
                pattern: "Total\\s*Marks\\s*\\(In\\s*Words\\)[\\s\\S]*?<td\\s+align=\"center\">\\s*<b\\s+class=\"text-danger\">\\s*[0-9.]+\\s*</b>\\s*</td>\\s*<td\\s+align=\"center\">\\s*<b\\s+class=\"text-danger\">\\s*([0-9.]+)"
            ) ?? ""
        )
        let percentage: Double? = {
            guard let maxMarks, let earnedMarks, maxMarks > 0 else { return nil }
            return (earnedMarks / maxMarks) * 100
        }()
        guard let gpa else { return nil }

        let resultText = HTMLParsingSupport.stripTags(
            HTMLParsingSupport.firstMatch(
                in: resultHTML,
                pattern: "Result\\s*:\\s*<span[^>]*>([^<]+)</span>"
            ) ?? ""
        )
        let credits = HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(
                in: resultHTML,
                pattern: "Total\\s*Credits\\s*Awarded\\s*:\\s*<span[^>]*>\\s*([0-9.]+)"
            ) ?? ""
        )
        let subjectRows = parseSubjectRows(resultHTML)
        let detail = SemesterRecordDetail(
            examLabel: option.examLabel,
            resultText: resultText.isEmpty ? nil : resultText,
            totalCreditsAwarded: credits,
            totalMarksAwarded: earnedMarks,
            totalMarksMaximum: maxMarks,
            subjectRows: subjectRows
        )
        return SemesterRecord(
            id: UUID(),
            displayTitle: option.displayTitle,
            gpa: gpa,
            percentage: percentage ?? 0,
            detail: detail
        )
    }

    func parse(selectionHTML: String, resultHTML: String) -> AcademicsPageData {
        let semesterOptions = parseExamOptions(selectionHTML)

        let degree = HTMLParsingSupport.stripTags(
            HTMLParsingSupport.firstMatch(in: resultHTML, pattern: "<td>\\s*Degree\\s*</td>\\s*<td>(.*?)</td>") ?? ""
        )
        let trimester = HTMLParsingSupport.stripTags(
            HTMLParsingSupport.firstMatch(in: resultHTML, pattern: "<td>\\s*Trimester\\s*</td>\\s*<td>(.*?)</td>") ?? ""
        )
        let gpa = HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(in: resultHTML, pattern: "Grade\\s*Points\\s*Average\\s*:\\s*<span[^>]*>([0-9.]+)") ?? ""
        )

        let maxMarks = HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(in: resultHTML, pattern: "<b\\s+class=\"text-danger\">\\s*([0-9.]+)\\s*</b>\\s*</td>\\s*<td\\s+align=\"center\">\\s*<b\\s+class=\"text-danger\">") ?? ""
        ) ?? 0
        let earnedMarks = HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(in: resultHTML, pattern: "<td\\s+align=\"center\">\\s*<b\\s+class=\"text-danger\">\\s*[0-9.]+\\s*</b>\\s*</td>\\s*<td\\s+align=\"center\">\\s*<b\\s+class=\"text-danger\">\\s*([0-9.]+)") ?? ""
        ) ?? 0
        let percentage = maxMarks > 0 ? (earnedMarks / maxMarks) * 100 : nil

        let recordTitle = semesterOptions.last?.displayTitle
            ?? (!trimester.isEmpty ? "Semester \(trimester)" : "Semester I")
        let records = gpa.map {
            [SemesterRecord(id: UUID(), displayTitle: recordTitle, gpa: $0, percentage: percentage ?? 0)]
        } ?? []

        return AcademicsPageData(
            programTitle: degree.isEmpty ? nil : degree,
            currentSemesterLabel: trimester.isEmpty ? nil : "Semester \(trimester)",
            cumulativeGPA: gpa,
            overallPercentage: percentage,
            records: records
        )
    }

    private func parseSubjectRows(_ html: String) -> [SemesterSubjectMark] {
        guard let rowRegex = try? NSRegularExpression(
            pattern: "<tr[^>]*>([\\s\\S]*?)</tr>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ), let cellRegex = try? NSRegularExpression(
            pattern: "<td[^>]*>([\\s\\S]*?)</td>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }

        let fullRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let rowMatches = rowRegex.matches(in: html, options: [], range: fullRange)
        var rows: [SemesterSubjectMark] = []

        for rowMatch in rowMatches {
            guard let rowRange = Range(rowMatch.range(at: 1), in: html) else { continue }
            let rowHTML = String(html[rowRange])
            let rowNSRange = NSRange(rowHTML.startIndex..<rowHTML.endIndex, in: rowHTML)
            let cellMatches = cellRegex.matches(in: rowHTML, options: [], range: rowNSRange)
            let cells = cellMatches.compactMap { match -> String? in
                guard let captureRange = Range(match.range(at: 1), in: rowHTML) else { return nil }
                let text = HTMLParsingSupport.stripTags(String(rowHTML[captureRange]))
                return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard cells.count >= 8 else { continue }
            let serial = cells[0]
            guard Int(serial) != nil else { continue }
            // Skip footer/summary style rows that may begin numeric accidentally.
            let rowJoined = cells.joined(separator: " ").lowercased()
            if rowJoined.contains("total marks")
                || rowJoined.contains("result :")
                || rowJoined.contains("grade points average")
            {
                continue
            }

            let subject = cells[1]
            let type = cells[2]
            if subject.isEmpty || subject.lowercased() == "subject" { continue }

            // Last five cells are consistently: TOTAL max, TOTAL awarded, credits, grade, status.
            let tail = Array(cells.suffix(5))
            guard tail.count == 5 else { continue }
            let totalMax = tail[0]
            let totalAwarded = tail[1]
            let credits = tail[2]
            let grade = tail[3]
            let status = tail[4]
            let middle = Array(cells.dropFirst(3).dropLast(5))

            let ciaMax = middle.indices.contains(0) ? middle[0] : nil
            let ciaAwarded = middle.indices.contains(1) ? middle[1] : nil

            let attendanceMax: String?
            let attendanceAwarded: String?
            let eseMax: String?
            let eseMin: String?
            let eseAwarded: String?

            if middle.count >= 7 {
                attendanceMax = middle[2]
                attendanceAwarded = middle[3]
                eseMax = middle[4]
                eseMin = middle[5]
                eseAwarded = middle[6]
            } else if middle.count >= 5 {
                attendanceMax = nil
                attendanceAwarded = nil
                eseMax = middle[2]
                eseMin = middle[3]
                eseAwarded = middle[4]
            } else {
                attendanceMax = nil
                attendanceAwarded = nil
                eseMax = nil
                eseMin = nil
                eseAwarded = nil
            }

            rows.append(
                SemesterSubjectMark(
                    id: UUID(),
                    serialNumber: serial,
                    subject: subject,
                    type: type,
                    ciaMaxMarks: ciaMax,
                    ciaMarksAwarded: ciaAwarded,
                    attendanceMaxMarks: attendanceMax,
                    attendanceMarksAwarded: attendanceAwarded,
                    eseMaxMarks: eseMax,
                    eseMinMarks: eseMin,
                    eseMarksAwarded: eseAwarded,
                    totalMaxMarks: totalMax,
                    totalMarksAwarded: totalAwarded,
                    credits: credits,
                    grade: grade,
                    status: status
                )
            )
        }

        return rows
    }
}
