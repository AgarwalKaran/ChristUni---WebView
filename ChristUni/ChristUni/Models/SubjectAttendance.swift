//
//  SubjectAttendance.swift
//  ChristUni
//

import Foundation

struct SubjectAttendance: Identifiable, Sendable, Codable {
    let id: UUID
    var subjectName: String
    var courseCode: String
    var attendanceType: AttendanceType
    var classesConducted: Int
    var present: Int
    var absent: Int
    /// Optional status chip copy, e.g. "Low Attendance".
    var statusLabel: String?
    var statusIsWarning: Bool

    var percentage: Double {
        guard classesConducted > 0 else { return 0 }
        return (Double(present) / Double(classesConducted)) * 100
    }
}
