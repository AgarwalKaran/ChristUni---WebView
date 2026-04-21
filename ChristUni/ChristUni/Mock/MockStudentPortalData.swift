//
//  MockStudentPortalData.swift
//  ChristUni
//
//  Static mock snapshot — replace with API later.
//

import Foundation

enum MockStudentPortalData {
    static let snapshot: StudentPortalSnapshot = {
        let student = Student(
            id: UUID(),
            name: "Karan Agarwal",
            registerNumber: "6MCA B",
            mobileNumber: "+91 9988776655",
            personalEmail: "karanxprvt@gmail.com",
            profilePhotoURL: nil,
            overallAttendancePercentage: 88.5,
            programTitle: "Master of Computer Applications",
            currentSemesterLabel: "Semester VI • Academic Year 2025–26"
        )

        let todayClasses: [TodayClass] = [
            TodayClass(
                id: UUID(),
                startTime: "09:00",
                endTime: "10:00",
                title: "Advanced Algorithms",
                subtitle: "Block IV • Room 402",
                isLive: true
            ),
            TodayClass(
                id: UUID(),
                startTime: "11:30",
                endTime: "12:30",
                title: "Machine Learning",
                subtitle: "Central Lab • Station 12",
                isLive: false
            ),
        ]

        // Cumulative GPA in overview is the unweighted mean of term GPAs (v1 simplicity).
        let semesterRecords: [SemesterRecord] = [
            SemesterRecord(id: UUID(), displayTitle: "Semester VI", gpa: 3.92, percentage: 92),
            SemesterRecord(id: UUID(), displayTitle: "Semester V", gpa: 3.85, percentage: 88),
            SemesterRecord(id: UUID(), displayTitle: "Semester IV", gpa: 3.74, percentage: 85),
            SemesterRecord(id: UUID(), displayTitle: "Semester III", gpa: 3.90, percentage: 90),
            SemesterRecord(id: UUID(), displayTitle: "Semester II", gpa: 3.68, percentage: 82),
            SemesterRecord(id: UUID(), displayTitle: "Semester I", gpa: 3.55, percentage: 79),
        ]

        let termGPAs = semesterRecords.map(\.gpa)
        let cumulative = termGPAs.reduce(0, +) / Double(termGPAs.count)
        let termPercents = semesterRecords.map(\.percentage)
        let avgPercent = termPercents.reduce(0, +) / Double(termPercents.count)

        let overview = AcademicOverview(
            cumulativeGPA: (cumulative * 100).rounded() / 100,
            overallPercentage: (avgPercent * 10).rounded() / 10
        )

        let ongoingSubjects: [SubjectAttendance] = [
            SubjectAttendance(
                id: UUID(),
                subjectName: "Advanced Algorithm Analysis",
                courseCode: "BTCS601",
                attendanceType: .theory,
                classesConducted: 42,
                present: 31,
                absent: 11,
                statusLabel: "Low Attendance",
                statusIsWarning: true
            ),
            SubjectAttendance(
                id: UUID(),
                subjectName: "Deep Learning Lab",
                courseCode: "BTCS605",
                attendanceType: .practical,
                classesConducted: 25,
                present: 24,
                absent: 1,
                statusLabel: "Exemplary",
                statusIsWarning: false
            ),
            SubjectAttendance(
                id: UUID(),
                subjectName: "Cloud Architecture",
                courseCode: "BTCS602",
                attendanceType: .theory,
                classesConducted: 38,
                present: 33,
                absent: 5,
                statusLabel: nil,
                statusIsWarning: false
            ),
        ]

        let completedSubjects: [SubjectAttendance] = [
            SubjectAttendance(
                id: UUID(),
                subjectName: "Operating Systems",
                courseCode: "BTCS503",
                attendanceType: .theory,
                classesConducted: 45,
                present: 42,
                absent: 3,
                statusLabel: nil,
                statusIsWarning: false
            ),
            SubjectAttendance(
                id: UUID(),
                subjectName: "Database Systems Lab",
                courseCode: "BTCS504",
                attendanceType: .practical,
                classesConducted: 30,
                present: 28,
                absent: 2,
                statusLabel: nil,
                statusIsWarning: false
            ),
        ]

        let attendanceBundles: [SemesterAttendanceBundle] = [
            SemesterAttendanceBundle(
                id: UUID(),
                semesterTitle: "Semester VI",
                isOngoing: true,
                subjects: ongoingSubjects
            ),
            SemesterAttendanceBundle(
                id: UUID(),
                semesterTitle: "Semester V",
                isOngoing: false,
                subjects: completedSubjects
            ),
        ]

        let faculty: [Faculty] = [
            Faculty(
                id: UUID(),
                name: "Dr. Rajesh Subramanian",
                email: "rajesh.s@christuniversity.in",
                department: "Computer Science",
                cabin: "Cabin 402, Block B, 4th Floor",
                campus: "Central Campus, Bengaluru"
            ),
            Faculty(
                id: UUID(),
                name: "Dr. Ananya Sharma",
                email: "ananya.sharma@christuniversity.in",
                department: "Management & Commerce",
                cabin: "Cabin 112, Block C, Ground Floor",
                campus: "Bannerghatta Road Campus"
            ),
            Faculty(
                id: UUID(),
                name: "Prof. Michael Chen",
                email: "michael.chen@christuniversity.in",
                department: "Psychology & Social Sciences",
                cabin: "Cabin 205, Block A, 2nd Floor",
                campus: "Kengeri Campus"
            ),
            Faculty(
                id: UUID(),
                name: "Dr. Sarah Thompson",
                email: "sarah.t@christuniversity.in",
                department: "Department of Humanities",
                cabin: "Research Lab 08, Block D",
                campus: "Central Campus, Bengaluru"
            ),
            Faculty(
                id: UUID(),
                name: "Dr. Vikram Mehta",
                email: "vikram.mehta@christuniversity.in",
                department: "Computer Science",
                cabin: "Cabin 318, Block B, 3rd Floor",
                campus: "Central Campus, Bengaluru"
            ),
            Faculty(
                id: UUID(),
                name: "Prof. Lakshmi Narayan",
                email: "lakshmi.n@christuniversity.in",
                department: "Physics & Electronics",
                cabin: "Cabin 201, Block A, 2nd Floor",
                campus: "Kengeri Campus"
            ),
        ]

        return StudentPortalSnapshot(
            student: student,
            todayClasses: todayClasses,
            academicOverview: overview,
            semesterRecords: semesterRecords,
            attendanceBundles: attendanceBundles,
            faculty: faculty
        )
    }()
}
