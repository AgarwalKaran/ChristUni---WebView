//
//  Faculty.swift
//  ChristUni
//

import Foundation

struct Faculty: Identifiable, Sendable, Codable {
    let id: UUID
    var name: String
    var email: String
    var department: String
    var cabin: String
    var campus: String
}
