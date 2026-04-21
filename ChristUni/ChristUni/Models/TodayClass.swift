//
//  TodayClass.swift
//  ChristUni
//
//  Optional dashboard schedule row (mock).
//

import Foundation

struct TodayClass: Identifiable, Sendable, Codable {
    let id: UUID
    var startTime: String
    var endTime: String
    var title: String
    var subtitle: String
    var isLive: Bool
}
