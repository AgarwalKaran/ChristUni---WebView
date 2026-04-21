//
//  ChristUniTests.swift
//  ChristUniTests
//
//  Created by Karan Agarwal on 12/04/26.
//

import Testing
@testable import ChristUni

struct ChristUniTests {

    @Test func subjectAttendancePercentageUsesPresentOverConducted() {
        let subject = SubjectAttendance(
            id: UUID(),
            subjectName: "Test",
            courseCode: "TST101",
            attendanceType: .theory,
            classesConducted: 40,
            present: 30,
            absent: 10,
            statusLabel: nil,
            statusIsWarning: true
        )
        #expect(subject.percentage == 75)
    }

    @Test func mockSnapshotHasFourMainDataDomains() {
        let s = MockStudentPortalData.snapshot
        #expect(s.semesterRecords.count >= 4)
        #expect(s.attendanceBundles.count == 2)
        #expect(s.faculty.count >= 4)
    }

    @Test func attendanceParserExtractsTotalsAndSubjects() {
        let html = """
        <div>Attendance For Class 6MCA B</div>
        <table>
        <tr><td width="40%" height="25">Advanced Algorithms</td>
        <td width="55%" height="25" align="center"><table>
        <tr><td width="20%" height="25" align="center">Theory</td><td width="20%" height="25" align="right">40</td><td width="20%" height="25" align="right">36</td><td width="20%" height="25" align="right"><u>4</u></td><td width="20%" height="25" align="right">90.00</td></tr>
        </table></td></tr>
        <tr><td>Total Percentage</td><td><div align="right">94.71 </div></td></tr>
        </table>
        """
        let parsed = AttendanceHTMLParser().parse(html)
        #expect(parsed.semesterTitle.contains("6MCA B"))
        #expect(parsed.subjects.count == 1)
        #expect(abs((parsed.overallPercentage ?? 0) - 94.71) < 0.01)
    }

    @Test func academicsParserExtractsGpaAndPercentage() {
        let selectHTML = """
        <option value="1741_1">Sem:1-(OCTOBER 2024)</option>
        """
        let resultHTML = """
        <td>Degree</td><td>Master of Computer Applications</td>
        <td>Trimester</td><td>I</td>
        Month &amp; Year of Examination</td><td>OCTOBER 2024</td>
        Grade Points Average : <span class="text-danger">3.96</span>
        <td align="center"><b class="text-danger">600</b></td>
        <td align="center"><b class="text-danger">527</b></td>
        """
        let parsed = AcademicsHTMLParser().parse(selectionHTML: selectHTML, resultHTML: resultHTML)
        #expect(abs((parsed.cumulativeGPA ?? 0) - 3.96) < 0.001)
        #expect(parsed.programTitle == "Master of Computer Applications")
        #expect(parsed.records.count == 1)
    }

    @Test func facultyParserExtractsFacultyRows() {
        let html = """
        <tr class="row-even">
            <td><div align="center">1</div></td>
            <td align="center">PETER AUGUSTIN D</td>
            <td align="center">peter.augustine@christuniversity.in</td>
            <td align="center">COMPUTER SCIENCE</td>
            <td align="center">974,NINTH Floor,CENTRAL BLOCK</td>
            <td align="center">1:30 PM to 2:30 3:30 to 4:30</td>
            <td align="center">BANGALORE CENTRAL CAMPUS</td>
        </tr>
        """
        let faculty = FacultyHTMLParser().parse(html)
        #expect(faculty.count == 1)
        #expect(faculty.first?.department == "COMPUTER SCIENCE")
    }

    @Test func cookieSerializationRoundTripPreservesName() {
        let cookie = HTTPCookie(properties: [
            .domain: "kp.christuniversity.in",
            .path: "/",
            .name: "JSESSIONID",
            .value: "abc123",
            .secure: true
        ])
        #expect(cookie != nil)
        let encoded = PortalAuthSessionStore.serialize(cookies: [cookie!])
        let decoded = PortalAuthSessionStore.deserialize(entries: encoded)
        #expect(decoded.first?.name == "JSESSIONID")
    }
}
