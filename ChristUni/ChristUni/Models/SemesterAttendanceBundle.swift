//
//  SemesterAttendanceBundle.swift
//  ChristUni
//

import Foundation

struct SemesterAttendanceBundle: Identifiable, Sendable, Codable {
    let id: UUID
    var semesterTitle: String
    var isOngoing: Bool
    var subjects: [SubjectAttendance]
}
