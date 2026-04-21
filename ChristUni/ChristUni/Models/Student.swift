//
//  Student.swift
//  ChristUni
//

import Foundation

struct Student: Identifiable, Sendable, Codable {
    let id: UUID
    var name: String
    var registerNumber: String
    var mobileNumber: String
    var personalEmail: String
    var profilePhotoURL: String?
    /// Overall attendance across active programme (mock).
    var overallAttendancePercentage: Double
    var programTitle: String
    var currentSemesterLabel: String
}
