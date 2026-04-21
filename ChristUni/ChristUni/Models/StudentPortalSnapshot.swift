//
//  StudentPortalSnapshot.swift
//  ChristUni
//
//  Single mock payload for the whole app.
//

import Foundation

struct StudentPortalSnapshot: Sendable, Codable {
    var student: Student
    var todayClasses: [TodayClass]
    var academicOverview: AcademicOverview
    var semesterRecords: [SemesterRecord]
    var attendanceBundles: [SemesterAttendanceBundle]
    var faculty: [Faculty]
}
