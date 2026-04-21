import Foundation

struct PortalSnapshotPayload {
    let snapshot: StudentPortalSnapshot
    let diagnostics: [String: String]
}

struct FacultyDirectoryPayload {
    let departments: [String]
    let faculty: [Faculty]
}

@MainActor
protocol StudentPortalRepository {
    func fetchSnapshot() async throws -> PortalSnapshotPayload
    func fetchFacultyDirectory(department: String?, employeeName: String?) async throws -> FacultyDirectoryPayload
}

@MainActor
struct LiveStudentPortalRepository: StudentPortalRepository {
    private let client: AuthenticatedHTTPClient
    private let renderedFetcher: PortalRenderedPageFetcher
    private let homeParser = HomeHTMLParser()
    private let attendanceParser = AttendanceHTMLParser()
    private let academicsParser = AcademicsHTMLParser()
    private let facultyParser = FacultyHTMLParser()

    init(
        client: AuthenticatedHTTPClient? = nil,
        renderedFetcher: PortalRenderedPageFetcher? = nil
    ) {
        self.client = client ?? AuthenticatedHTTPClient()
        self.renderedFetcher = renderedFetcher ?? PortalRenderedPageFetcher()
    }

    func fetchSnapshot() async throws -> PortalSnapshotPayload {
        let home = try await renderedFetcher.fetch(
            endpointKey: "home",
            endpointMap: client.endpointMap
        )
        let attendanceCurrent = try await fetchBestAttendanceResponse()
        let attendancePreviousSelection = try await renderedFetcher.fetch(
            endpointKey: "attendance",
            endpointMap: client.endpointMap
        )
        let academicsSelect = try await renderedFetcher.fetch(
            endpointKey: "academicsSelect",
            endpointMap: client.endpointMap
        )
        let facultySelect = try await renderedFetcher.fetch(
            endpointKey: "facultySelect",
            endpointMap: client.endpointMap
        )

        let academicsResults = try await fetchAcademicsResponses(selectionHTML: academicsSelect.html)
        let previousAttendanceResponses = try await fetchPreviousAttendanceResponses(selectionHTML: attendancePreviousSelection.html)

        var responses = [home, attendanceCurrent, attendancePreviousSelection, academicsSelect, facultySelect]
        responses.append(contentsOf: academicsResults.map(\.response))
        responses.append(contentsOf: previousAttendanceResponses.map(\.response))
        let diagnostics = buildDiagnostics(responses)

        let homeData = homeParser.parse(home.html)
        let attendanceCurrentData = attendanceParser.parse(attendanceCurrent.html)
        let attendancePreviousData = previousAttendanceResponses.map { entry in
            let parsed = attendanceParser.parse(entry.response.html)
            return SemesterAttendanceBundle(
                id: UUID(),
                semesterTitle: entry.option.label,
                isOngoing: false,
                subjects: parsed.subjects
            )
        }.filter { !$0.subjects.isEmpty }
        let academicsData = buildAcademicsPageData(selectionHTML: academicsSelect.html, entries: academicsResults)
        let facultyPageData = facultyParser.parsePage(facultySelect.html)
        let previousSubjectCount = attendancePreviousData.reduce(0) { $0 + $1.subjects.count }
        print("PortalParse homeName=\(homeData.name ?? "nil") attendanceSubjects=\(attendanceCurrentData.subjects.count) previousAttendanceSubjects=\(previousSubjectCount) academicsRecords=\(academicsData.records.count) facultyCount=\(facultyPageData.faculty.count)")

        var snapshot = makeEmptyLiveSnapshot()
        if let name = homeData.name, !name.isEmpty {
            snapshot.student.name = name
        }
        if let registerNumber = homeData.classLabel, !registerNumber.isEmpty {
            snapshot.student.registerNumber = registerNumber
            if snapshot.student.currentSemesterLabel == "Unavailable" {
                snapshot.student.currentSemesterLabel = registerNumber
            }
        }
        if let mobileNumber = homeData.mobileNumber, isMeaningful(homeField: mobileNumber) {
            snapshot.student.mobileNumber = mobileNumber
        }
        if let personalEmail = homeData.personalEmail, isMeaningful(homeField: personalEmail) {
            snapshot.student.personalEmail = personalEmail
        }
        if let profilePhotoURL = homeData.profilePhotoURL, !profilePhotoURL.isEmpty {
            snapshot.student.profilePhotoURL = profilePhotoURL
        }
        if let homeProgramTitle = homeData.programTitle, !homeProgramTitle.isEmpty {
            snapshot.student.programTitle = homeProgramTitle
        } else if snapshot.student.programTitle == "Unavailable",
                  let registerNumber = homeData.classLabel,
                  !registerNumber.isEmpty {
            snapshot.student.programTitle = "Class \(registerNumber)"
        }
        if let programTitle = academicsData.programTitle, !programTitle.isEmpty {
            snapshot.student.programTitle = programTitle
        }
        if let semesterLabel = academicsData.currentSemesterLabel, !semesterLabel.isEmpty {
            snapshot.student.currentSemesterLabel = semesterLabel
        }
        if let attendance = attendanceCurrentData.overallPercentage, attendance > 0 {
            snapshot.student.overallAttendancePercentage = attendance
        }

        if let gpa = academicsData.cumulativeGPA, gpa > 0 {
            snapshot.academicOverview.cumulativeGPA = gpa
        }
        if let percentage = academicsData.overallPercentage, percentage > 0 {
            snapshot.academicOverview.overallPercentage = percentage
        }
        if !academicsData.records.isEmpty {
            snapshot.semesterRecords = academicsData.records
        }

        let currentBundle = SemesterAttendanceBundle(
            id: UUID(),
            semesterTitle: attendanceCurrentData.semesterTitle,
            isOngoing: true,
            subjects: attendanceCurrentData.subjects
        )
        var bundles: [SemesterAttendanceBundle] = []
        if !currentBundle.subjects.isEmpty {
            bundles.append(currentBundle)
        }
        bundles.append(contentsOf: attendancePreviousData)
        if !bundles.isEmpty {
            snapshot.attendanceBundles = bundles
        }
        if !facultyPageData.faculty.isEmpty {
            snapshot.faculty = facultyPageData.faculty
        }

        return PortalSnapshotPayload(snapshot: snapshot, diagnostics: diagnostics)
    }

    func fetchFacultyDirectory(department: String?, employeeName: String?) async throws -> FacultyDirectoryPayload {
        let facultySelect = try await renderedFetcher.fetch(
            endpointKey: "facultySelect",
            endpointMap: client.endpointMap
        )
        let initialData = facultyParser.parsePage(facultySelect.html)
        let departmentText = department?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let employeeText = employeeName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let shouldSearch = !departmentText.isEmpty || !employeeText.isEmpty
        guard shouldSearch else {
            return FacultyDirectoryPayload(departments: initialData.departments, faculty: initialData.faculty)
        }

        let detailResponse = try await renderedFetcher.fetch(
            endpointKey: "facultyInfo",
            endpointMap: client.endpointMap,
            method: "POST",
            form: [
                "formName": "facultylocationform",
                "pageType": "1",
                "method": "searchDetails",
                "departmentId": "",
                "deptName": departmentText,
                "employeeName": employeeText,
                "empId": "0"
            ]
        )
        let detailData = facultyParser.parsePage(detailResponse.html)
        return FacultyDirectoryPayload(
            departments: detailData.departments.isEmpty ? initialData.departments : detailData.departments,
            faculty: detailData.faculty
        )
    }

    private func fetchBestAttendanceResponse() async throws -> EndpointHTMLResponse {
        let keys = ["attendanceSummary", "attendanceCurrentA", "attendanceCurrentB", "attendance"]
        var fallback: EndpointHTMLResponse?
        for key in keys {
            let response = try await renderedFetcher.fetch(endpointKey: key, endpointMap: client.endpointMap)
            if responseHasAttendanceData(response.html) { return response }
            if fallback == nil { fallback = response }
        }
        if let fallback { return fallback }
        return try await renderedFetcher.fetch(endpointKey: "attendance", endpointMap: client.endpointMap)
    }

    private func fetchPreviousAttendanceResponses(selectionHTML: String) async throws -> [(option: PreviousAttendanceOption, response: EndpointHTMLResponse)] {
        let options = previousAttendanceOptions(in: selectionHTML)
        var results: [(option: PreviousAttendanceOption, response: EndpointHTMLResponse)] = []
        for option in options {
            let response = try await renderedFetcher.fetch(
                endpointKey: "attendancePreviousResult",
                endpointMap: client.endpointMap,
                method: "POST",
                form: [
                    "method": "getPreviousStudentWiseSubjectSummaryChrist",
                    "formName": "studentWiseAttendanceSummaryForm",
                    "pageType": "4",
                    "classesId": option.classesId
                ]
            )
            if responseHasAttendanceData(response.html) {
                results.append((option, response))
            }
        }
        return results
    }

    private func fetchAcademicsResponses(selectionHTML: String) async throws -> [(option: AcademicsExamOption, response: EndpointHTMLResponse)] {
        let options = academicsParser.parseExamOptions(selectionHTML)
        var results: [(option: AcademicsExamOption, response: EndpointHTMLResponse)] = []
        for option in options {
            if let response = try await fetchBestAcademicsResponse(selectedExamId: option.examId) {
                results.append((option, response))
            }
        }
        return results
    }

    private func fetchBestAcademicsResponse(selectedExamId: String) async throws -> EndpointHTMLResponse? {
        let payloads: [[String: String]] = [
            [
                "formName": "loginform",
                "pageType": "3",
                "method": "MarksCardDisplay",
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "suppExamId": ""
            ],
            [
                "method": "getMarkscard",
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "formName": "loginform",
                "pageType": "3"
            ],
            [
                "method": "getMarksCard",
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "formName": "loginform",
                "pageType": "3"
            ],
            [
                "method": "printMarksCard",
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "formName": "loginform",
                "pageType": "3"
            ],
            [
                "method": "printMarksCard",
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "formName": "loginform",
                "marksCardType": "regPg",
                "pageType": "1"
            ],
            [
                "method": "getMarkscard",
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "formName": "loginform",
                "marksCardType": "regPg",
                "pageType": "1"
            ]
        ]
        let getPayloads: [[String: String]] = [
            [
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "formName": "loginform",
                "marksCardType": "regPg",
                "pageType": "1"
            ],
            [
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "formName": "loginform",
                "pageType": "3"
            ],
            [
                "method": "printMarksCard",
                "examType": "Regular",
                "regularExamId": selectedExamId,
                "formName": "loginform",
                "pageType": "1"
            ]
        ]
        var fallback: EndpointHTMLResponse?
        for form in payloads {
            let response = try await renderedFetcher.fetch(
                endpointKey: "academicsResult",
                endpointMap: client.endpointMap,
                method: "POST",
                form: form
            )
            if responseHasAcademicsData(response.html) { return response }
            if fallback == nil { fallback = response }
        }
        for form in getPayloads {
            let response = try await renderedFetcher.fetch(
                endpointKey: "academicsResultPrint",
                endpointMap: client.endpointMap,
                method: "GET",
                form: form
            )
            if responseHasAcademicsData(response.html) { return response }
            if fallback == nil { fallback = response }
        }
        return fallback
    }

    private func buildAcademicsPageData(
        selectionHTML: String,
        entries: [(option: AcademicsExamOption, response: EndpointHTMLResponse)]
    ) -> AcademicsPageData {
        let sorted = entries.sorted { $0.option.semesterNumber > $1.option.semesterNumber }
        let records = sorted.compactMap { entry in
            academicsParser.parseSemesterResult(resultHTML: entry.response.html, option: entry.option)
        }

        var programTitle: String?
        var currentSemesterLabel: String?
        for entry in sorted {
            let parsed = academicsParser.parse(selectionHTML: selectionHTML, resultHTML: entry.response.html)
            if programTitle == nil, let title = parsed.programTitle, !title.isEmpty {
                programTitle = title
            }
            if currentSemesterLabel == nil, let label = parsed.currentSemesterLabel, !label.isEmpty {
                currentSemesterLabel = label
            }
            if programTitle != nil && currentSemesterLabel != nil {
                break
            }
        }

        let avgGPA: Double? = records.isEmpty ? nil : records.map(\.gpa).reduce(0, +) / Double(records.count)
        let avgPercent: Double? = records.isEmpty ? nil : records.map(\.percentage).reduce(0, +) / Double(records.count)

        return AcademicsPageData(
            programTitle: programTitle,
            currentSemesterLabel: currentSemesterLabel,
            cumulativeGPA: avgGPA,
            overallPercentage: avgPercent,
            records: records
        )
    }

    private func makeEmptyLiveSnapshot() -> StudentPortalSnapshot {
        StudentPortalSnapshot(
            student: Student(
                id: UUID(),
                name: "Unavailable",
                registerNumber: "-",
                mobileNumber: "-",
                personalEmail: "-",
                profilePhotoURL: nil,
                overallAttendancePercentage: 0,
                programTitle: "Unavailable",
                currentSemesterLabel: "Unavailable"
            ),
            todayClasses: [],
            academicOverview: AcademicOverview(cumulativeGPA: 0, overallPercentage: 0),
            semesterRecords: [],
            attendanceBundles: [
                SemesterAttendanceBundle(id: UUID(), semesterTitle: "Ongoing", isOngoing: true, subjects: []),
                SemesterAttendanceBundle(id: UUID(), semesterTitle: "Completed", isOngoing: false, subjects: [])
            ],
            faculty: []
        )
    }

    private func buildDiagnostics(_ responses: [EndpointHTMLResponse]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: responses.enumerated().map { index, response in
            let markers = [
                "signOut:\(response.html.localizedCaseInsensitiveContains("Sign out"))",
                "marksCard:\(response.html.localizedCaseInsensitiveContains("My Marks Card"))",
                "attendanceTable:\(response.html.localizedCaseInsensitiveContains("Total Percentage"))",
                "facultyTable:\(response.html.localizedCaseInsensitiveContains("Faculty Location"))",
                "profileName:\(response.html.localizedCaseInsensitiveContains("Name Of Candidate"))",
                "subjectNameCol:\(response.html.localizedCaseInsensitiveContains("Subject Name"))"
            ].joined(separator: ",")
            let finalURL = response.finalURL?.absoluteString ?? "nil"
            let value = "status=\(response.statusCode) request=\(response.requestURL.absoluteString) final=\(finalURL) markers[\(markers)]"
            print("PortalTrace[\(response.endpointKey)] \(value)")
            let duplicateCount = responses[..<index].filter { $0.endpointKey == response.endpointKey }.count
            let key = duplicateCount == 0 ? response.endpointKey : "\(response.endpointKey)#\(duplicateCount + 1)"
            return (key, value)
        })
    }

    private func previousAttendanceOptions(in selectionHTML: String) -> [PreviousAttendanceOption] {
        guard let regex = try? NSRegularExpression(
            pattern: "<option\\s+value=\"([^\"]+)\">\\s*([^<]+)\\s*</option>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }
        let range = NSRange(selectionHTML.startIndex..<selectionHTML.endIndex, in: selectionHTML)
        let matches = regex.matches(in: selectionHTML, options: [], range: range)
        return matches.compactMap { match in
            guard
                let idRange = Range(match.range(at: 1), in: selectionHTML),
                let labelRange = Range(match.range(at: 2), in: selectionHTML)
            else {
                return nil
            }
            let classesId = String(selectionHTML[idRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let label = HTMLParsingSupport.stripTags(String(selectionHTML[labelRange]))
            let lowered = label.lowercased()
            guard
                !classesId.isEmpty,
                classesId != "0",
                !lowered.contains("select")
            else {
                return nil
            }
            return PreviousAttendanceOption(classesId: classesId, label: label)
        }.reversed()
    }

    private func responseHasAttendanceData(_ html: String) -> Bool {
        html.localizedCaseInsensitiveContains("Total Percentage")
            || html.localizedCaseInsensitiveContains("Attendance For Class")
            || html.localizedCaseInsensitiveContains("Subject Name")
    }

    private func responseHasAcademicsData(_ html: String) -> Bool {
        html.localizedCaseInsensitiveContains("Name Of Candidate")
            || html.localizedCaseInsensitiveContains("Grade Points Average")
            || html.localizedCaseInsensitiveContains("STATEMENT OF MARKS")
    }

    private func isMeaningful(homeField: String) -> Bool {
        let trimmed = homeField.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != ":" && trimmed != "-"
    }
}

private struct PreviousAttendanceOption {
    let classesId: String
    let label: String
}
