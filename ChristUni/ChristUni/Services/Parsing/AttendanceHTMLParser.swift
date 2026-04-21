import Foundation

struct AttendancePageData {
    var semesterTitle: String
    var overallPercentage: Double?
    var subjects: [SubjectAttendance]
}

struct AttendanceHTMLParser {
    func parse(_ html: String) -> AttendancePageData {
        let semester = HTMLParsingSupport.stripTags(
            HTMLParsingSupport.firstMatch(in: html, pattern: "Attendance\\s*For\\s*Class\\s*([^<]+)") ?? "Current Semester"
        )

        let overallPercentage = parseOverallPercentage(from: html)
        let subjects = parseSubjectRows(from: html)

        return AttendancePageData(
            semesterTitle: semester.isEmpty ? "Current Semester" : semester,
            overallPercentage: overallPercentage,
            subjects: subjects
        )
    }

    private func parseOverallPercentage(from html: String) -> Double? {
        if let strict = HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(
                in: html,
                pattern: "Total\\s*Percentage.*?<div[^>]*>\\s*([0-9]+(?:\\.[0-9]+)?)\\s*</div>"
            ) ?? ""
        ) {
            return strict
        }
        return HTMLParsingSupport.firstDouble(
            in: HTMLParsingSupport.firstMatch(
                in: html,
                pattern: "Total\\s*Percentage[\\s\\S]*?([0-9]+(?:\\.[0-9]+)?)\\s*</div>"
            ) ?? ""
        )
    }

    private func parseSubjectRows(from html: String) -> [SubjectAttendance] {
        let outerRowPattern = #"<tr[^>]*>\s*<td[^>]*>\s*(?:<div[^>]*>)?\s*[0-9]+\s*(?:</div>)?\s*</td>\s*<td[^>]*>\s*(.*?)\s*</td>\s*<td[^>]*>\s*<table[^>]*>([\s\S]*?)</table>\s*</td>[\s\S]*?</tr>"#
        guard let outerRegex = try? NSRegularExpression(
            pattern: outerRowPattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let outerMatches = outerRegex.matches(in: html, options: [], range: range)

        let innerRowPattern = #"<tr[^>]*>\s*<td[^>]*>\s*(Theory|Practical|Asynchronous|Extra\s*Curricular)\s*</td>\s*<td[^>]*>\s*([0-9]+(?:\.[0-9]+)?)\s*</td>\s*<td[^>]*>\s*([0-9]+(?:\.[0-9]+)?)\s*</td>\s*<td[^>]*>\s*(?:<a[^>]*>\s*<u>)?\s*([0-9]+(?:\.[0-9]+)?)\s*(?:</u>\s*</a>)?"#
        guard let innerRegex = try? NSRegularExpression(
            pattern: innerRowPattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }

        var results: [SubjectAttendance] = []
        var rowIndex = 1

        for outerMatch in outerMatches {
            guard
                let subjectRange = Range(outerMatch.range(at: 1), in: html),
                let innerTableRange = Range(outerMatch.range(at: 2), in: html)
            else {
                continue
            }

            let subjectName = HTMLParsingSupport.stripTags(String(html[subjectRange]))
            if subjectName.isEmpty || subjectName.localizedCaseInsensitiveContains("subject name") {
                continue
            }

            let innerTableHTML = String(html[innerTableRange])
            let innerRange = NSRange(innerTableHTML.startIndex..<innerTableHTML.endIndex, in: innerTableHTML)
            let innerMatches = innerRegex.matches(in: innerTableHTML, options: [], range: innerRange)

            for innerMatch in innerMatches {
                func capture(_ i: Int) -> String {
                    guard let captureRange = Range(innerMatch.range(at: i), in: innerTableHTML) else { return "" }
                    return HTMLParsingSupport.stripTags(String(innerTableHTML[captureRange]))
                }
                func numericInt(_ value: String) -> Int {
                    Int(value) ?? Int((Double(value) ?? 0).rounded())
                }

                let typeRaw = capture(1)
                let conducted = numericInt(capture(2))
                let present = numericInt(capture(3))
                let absent = numericInt(capture(4))
                let lowered = typeRaw.lowercased()
                let attendanceType: AttendanceType
                if lowered.contains("practical") {
                    attendanceType = .practical
                } else if lowered.contains("asynchronous") {
                    attendanceType = .asynchronous
                } else if lowered.contains("extra") {
                    attendanceType = .extraCurricular
                } else {
                    attendanceType = .theory
                }
                let isLow = (Double(present) / max(Double(conducted), 1)) * 100 < 85

                results.append(
                    SubjectAttendance(
                        id: UUID(),
                        subjectName: subjectName,
                        courseCode: "SUB\(String(format: "%03d", rowIndex))",
                        attendanceType: attendanceType,
                        classesConducted: conducted,
                        present: present,
                        absent: absent,
                        statusLabel: isLow ? "Low Attendance" : nil,
                        statusIsWarning: isLow
                    )
                )
                rowIndex += 1
            }
        }

        return results
    }
}
