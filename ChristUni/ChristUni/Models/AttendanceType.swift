//
//  AttendanceType.swift
//  ChristUni
//

import Foundation

enum AttendanceType: String, CaseIterable, Identifiable, Sendable, Codable {
    case theory = "Theory"
    case practical = "Practical"
    case asynchronous = "Asynchronous"
    case extraCurricular = "Extra Curricular"

    var id: String { rawValue }
}
