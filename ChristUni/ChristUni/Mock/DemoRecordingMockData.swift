//
//  DemoRecordingMockData.swift
//  ChristUni
//
//  Fictitious dataset for screen recordings only. Profile image: Assets `DemoRecordingProfile`
//  (mock.png — copy your photo into `DemoRecordingProfile.imageset` and `Mock/mock.png`).
//  See `DemoRecordingSupport.swift` to strip.
//

import Foundation

enum DemoRecordingMockData {
    /// Department chips (must match `Faculty.department` strings used below).
    static let departmentNamesSorted: [String] = [
        "Department of Languages & Literature",
        "Department of Physical & Life Sciences",
        "School of Commerce & Management",
        "School of Computer Science & Information Technology",
    ]

    /// Full faculty roster for directory filtering (all departments loaded at once).
    static let allFaculty: [Faculty] = [
        Faculty(id: UUID(), name: "Dr. Aisha Rahman", email: "aisha.rahman@example.edu", department: departmentNamesSorted[3], cabin: "B-412", campus: "Central Campus"),
        Faculty(id: UUID(), name: "Prof. Daniel Okonkwo", email: "daniel.okonkwo@example.edu", department: departmentNamesSorted[3], cabin: "B-418", campus: "Central Campus"),
        Faculty(id: UUID(), name: "Dr. Mei-Lin Zhou", email: "meilin.zhou@example.edu", department: departmentNamesSorted[3], cabin: "Lab Wing L2", campus: "Central Campus"),

        Faculty(id: UUID(), name: "Prof. Eleanor Vargas", email: "eleanor.vargas@example.edu", department: departmentNamesSorted[2], cabin: "C-105", campus: "Bannerghatta Campus"),
        Faculty(id: UUID(), name: "Dr. James Porter", email: "james.porter@example.edu", department: departmentNamesSorted[2], cabin: "C-112", campus: "Bannerghatta Campus"),

        Faculty(id: UUID(), name: "Dr. Sunita Narayan", email: "sunita.narayan@example.edu", department: departmentNamesSorted[0], cabin: "A-203", campus: "Central Campus"),
        Faculty(id: UUID(), name: "Prof. Theo Laurent", email: "theo.laurent@example.edu", department: departmentNamesSorted[0], cabin: "A-208", campus: "Central Campus"),
        Faculty(id: UUID(), name: "Dr. Priya Balakrishnan", email: "priya.b@example.edu", department: departmentNamesSorted[0], cabin: "A-215", campus: "Central Campus"),

        Faculty(id: UUID(), name: "Dr. Omar Haddad", email: "omar.haddad@example.edu", department: departmentNamesSorted[1], cabin: "D-301", campus: "Kengeri Campus"),
        Faculty(id: UUID(), name: "Prof. Ingrid Dahl", email: "ingrid.dahl@example.edu", department: departmentNamesSorted[1], cabin: "D-307", campus: "Kengeri Campus"),
        Faculty(id: UUID(), name: "Dr. Felipe Martins", email: "felipe.martins@example.edu", department: departmentNamesSorted[1], cabin: "D-310", campus: "Kengeri Campus"),
    ]

    static let snapshot: StudentPortalSnapshot = {
        let semesterRecords = buildSemesterRecords()
        let attendanceBundles = buildAttendanceBundles()

        let ongoingConducted = attendanceBundles.first(where: \.isOngoing)?.subjects.reduce(0) { $0 + $1.classesConducted } ?? 1
        let ongoingPresent = attendanceBundles.first(where: \.isOngoing)?.subjects.reduce(0) { $0 + $1.present } ?? 1
        let heroAttendancePct = (Double(ongoingPresent) / Double(ongoingConducted)) * 100

        let termGPAs = semesterRecords.map(\.gpa)
        let cumulative = termGPAs.reduce(0, +) / Double(termGPAs.count)
        let termPercents = semesterRecords.map(\.percentage)
        let avgPercent = termPercents.reduce(0, +) / Double(termPercents.count)

        let student = Student(
            id: UUID(),
            name: "Xavier Morgan",
            registerNumber: "6 MCA B",
            mobileNumber: "+91 90000 00000",
            personalEmail: "xavier.morgan@christuniversity.in",
            profilePhotoURL: nil,
            overallAttendancePercentage: (heroAttendancePct * 100).rounded() / 100,
            programTitle: "Master of Computer Applications",
            currentSemesterLabel: "6 MCA B"
        )

        let todayClasses: [TodayClass] = [
            TodayClass(id: UUID(), startTime: "09:15", endTime: "10:30", title: "Advanced Software Engineering", subtitle: "Block B · Lab 03", isLive: true),
            TodayClass(id: UUID(), startTime: "13:30", endTime: "14:45", title: "Machine Learning Workshop", subtitle: "Seminar Hall 2", isLive: false),
        ]

        let overview = AcademicOverview(
            cumulativeGPA: (cumulative * 100).rounded() / 100,
            overallPercentage: (avgPercent * 10).rounded() / 10
        )

        return StudentPortalSnapshot(
            student: student,
            todayClasses: todayClasses,
            academicOverview: overview,
            semesterRecords: semesterRecords,
            attendanceBundles: attendanceBundles,
            faculty: allFaculty
        )
    }()

    // MARK: - Academics (Sem VI current + Sem I–V completed, all with marks detail)

    private static func buildSemesterRecords() -> [SemesterRecord] {
        let d6 = detail(
            credits: 22,
            awarded: 348,
            maximum: 400,
            subjects: [
                ("1", "Distributed Systems", "Theory", "86", "A"),
                ("2", "Machine Learning Laboratory", "Practical", "91", "A"),
                ("3", "Professional Ethics & IPR", "Theory", "82", "B+"),
                ("4", "Mobile Application Development", "Theory", "89", "A"),
            ],
            result: "Semester VI · Statement of Marks (Demo)"
        )
        let d5 = detail(credits: 20, awarded: 278, maximum: 320, subjects: [
            ("1", "Operating Systems", "Theory", "85", "A"),
            ("2", "Database Systems Lab", "Practical", "92", "A"),
            ("3", "Computer Networks", "Theory", "80", "B+"),
        ], result: nil)
        let d4 = detail(credits: 20, awarded: 268, maximum: 320, subjects: [
            ("1", "Data Structures & Algorithms", "Theory", "84", "A"),
            ("2", "Object Oriented Programming Lab", "Practical", "88", "A"),
            ("3", "Discrete Mathematical Structures", "Theory", "76", "B+"),
        ], result: nil)
        let d3 = detail(credits: 20, awarded: 255, maximum: 320, subjects: [
            ("1", "Programming in C", "Theory", "82", "A"),
            ("2", "Digital Systems Lab", "Practical", "79", "B+"),
            ("3", "Computer Organization", "Theory", "74", "B+"),
        ], result: nil)
        let d2 = detail(credits: 20, awarded: 246, maximum: 320, subjects: [
            ("1", "Python for Data Science", "Theory", "80", "B+"),
            ("2", "Web Technologies Lab", "Practical", "86", "A"),
            ("3", "Software Engineering", "Theory", "73", "B+"),
        ], result: nil)
        let d1 = detail(credits: 20, awarded: 238, maximum: 320, subjects: [
            ("1", "Problem Solving & Programming", "Theory", "77", "B+"),
            ("2", "Computer Fundamentals Lab", "Practical", "83", "A"),
            ("3", "Communicative English", "Theory", "71", "B"),
        ], result: nil)

        return [
            SemesterRecord(id: UUID(), displayTitle: "Semester VI", gpa: 3.76, percentage: 87.0, detail: d6),
            SemesterRecord(id: UUID(), displayTitle: "Semester V", gpa: 3.72, percentage: 85.4, detail: d5),
            SemesterRecord(id: UUID(), displayTitle: "Semester IV", gpa: 3.65, percentage: 83.8, detail: d4),
            SemesterRecord(id: UUID(), displayTitle: "Semester III", gpa: 3.58, percentage: 81.5, detail: d3),
            SemesterRecord(id: UUID(), displayTitle: "Semester II", gpa: 3.52, percentage: 79.6, detail: d2),
            SemesterRecord(id: UUID(), displayTitle: "Semester I", gpa: 3.45, percentage: 77.9, detail: d1),
        ]
    }

    private static func detail(
        credits: Double,
        awarded: Double,
        maximum: Double,
        subjects: [(String, String, String, String, String)],
        result: String?
    ) -> SemesterRecordDetail {
        let rows = subjects.map { s in
            semesterSubject(serial: s.0, subject: s.1, type: s.2, awarded: s.3, grade: s.4)
        }
        return SemesterRecordDetail(
            examLabel: "End Semester Examination",
            resultText: result,
            totalCreditsAwarded: credits,
            totalMarksAwarded: awarded,
            totalMarksMaximum: maximum,
            subjectRows: rows
        )
    }

    // MARK: - Attendance (Sem VI ongoing + Sem V…I completed)

    private static func buildAttendanceBundles() -> [SemesterAttendanceBundle] {
        let sem6: [SubjectAttendance] = [
            att("Advanced Software Engineering", "22MCA601", .theory, 42, 39, nil, false),
            att("Distributed Systems", "22MCA602", .theory, 40, 37, nil, false),
            att("Machine Learning Lab", "22MCA603P", .practical, 28, 25, "Attendance review", true),
        ]
        let sem5: [SubjectAttendance] = [
            att("Operating Systems", "22MCA501", .theory, 45, 42, nil, false),
            att("Database Systems Lab", "22MCA502P", .practical, 30, 29, nil, false),
            att("Computer Networks", "22MCA503", .theory, 40, 37, nil, false),
        ]
        let sem4: [SubjectAttendance] = [
            att("Data Structures & Algorithms", "22MCA401", .theory, 44, 41, nil, false),
            att("OOP Laboratory", "22MCA402P", .practical, 32, 30, nil, false),
            att("Discrete Mathematics", "22MCA403", .theory, 38, 35, nil, false),
        ]
        let sem3: [SubjectAttendance] = [
            att("Programming in C", "22MCA301", .theory, 42, 40, nil, false),
            att("Computer Organization", "22MCA302", .theory, 40, 38, nil, false),
            att("Digital Systems Lab", "22MCA303P", .practical, 26, 25, nil, false),
        ]
        let sem2: [SubjectAttendance] = [
            att("Python for Data Science", "22MCA201", .theory, 40, 37, nil, false),
            att("Software Engineering", "22MCA202", .theory, 38, 35, nil, false),
            att("Web Technologies Lab", "22MCA203P", .practical, 28, 27, nil, false),
        ]
        let sem1: [SubjectAttendance] = [
            att("Problem Solving & Programming", "22MCA101", .theory, 44, 42, nil, false),
            att("Computer Fundamentals Lab", "22MCA102P", .practical, 30, 28, nil, false),
            att("Communicative English", "22MCA103", .theory, 36, 34, nil, false),
        ]

        return [
            SemesterAttendanceBundle(id: UUID(), semesterTitle: "6 MCA B", isOngoing: true, subjects: sem6),
            SemesterAttendanceBundle(id: UUID(), semesterTitle: "5 MCA B", isOngoing: false, subjects: sem5),
            SemesterAttendanceBundle(id: UUID(), semesterTitle: "4 MCA B", isOngoing: false, subjects: sem4),
            SemesterAttendanceBundle(id: UUID(), semesterTitle: "3 MCA B", isOngoing: false, subjects: sem3),
            SemesterAttendanceBundle(id: UUID(), semesterTitle: "2 MCA B", isOngoing: false, subjects: sem2),
            SemesterAttendanceBundle(id: UUID(), semesterTitle: "1 MCA B", isOngoing: false, subjects: sem1),
        ]
    }

    private static func att(
        _ subject: String,
        _ code: String,
        _ type: AttendanceType,
        _ conducted: Int,
        _ present: Int,
        _ status: String?,
        _ warn: Bool
    ) -> SubjectAttendance {
        SubjectAttendance(
            id: UUID(),
            subjectName: subject,
            courseCode: code,
            attendanceType: type,
            classesConducted: conducted,
            present: present,
            absent: max(0, conducted - present),
            statusLabel: status,
            statusIsWarning: warn
        )
    }

    private static func semesterSubject(
        serial: String,
        subject: String,
        type: String,
        awarded: String,
        grade: String
    ) -> SemesterSubjectMark {
        SemesterSubjectMark(
            id: UUID(),
            serialNumber: serial,
            subject: subject,
            type: type,
            ciaMaxMarks: "40",
            ciaMarksAwarded: "34",
            attendanceMaxMarks: "10",
            attendanceMarksAwarded: "9",
            eseMaxMarks: "50",
            eseMinMarks: "20",
            eseMarksAwarded: "43",
            totalMaxMarks: "100",
            totalMarksAwarded: awarded,
            credits: "4",
            grade: grade,
            status: "Pass"
        )
    }
}
