//
//  SemesterRecord.swift
//  ChristUni
//
//  One row in Academic History — neutral title, no season labels.
//

import Foundation

struct SemesterRecord: Identifiable, Sendable, Codable {
    let id: UUID
    /// e.g. "Semester VI"
    var displayTitle: String
    /// 0...4 scale
    var gpa: Double
    /// Term percentage (mock).
    var percentage: Double
    var detail: SemesterRecordDetail? = nil
}

struct SemesterRecordDetail: Sendable, Codable {
    var examLabel: String
    var resultText: String?
    var totalCreditsAwarded: Double?
    var totalMarksAwarded: Double?
    var totalMarksMaximum: Double?
    var subjectRows: [SemesterSubjectMark]
}

struct SemesterSubjectMark: Identifiable, Sendable, Codable {
    let id: UUID
    var serialNumber: String
    var subject: String
    var type: String
    var ciaMaxMarks: String?
    var ciaMarksAwarded: String?
    var attendanceMaxMarks: String?
    var attendanceMarksAwarded: String?
    var eseMaxMarks: String?
    var eseMinMarks: String?
    var eseMarksAwarded: String?
    var totalMaxMarks: String
    var totalMarksAwarded: String
    var credits: String
    var grade: String
    var status: String
}
