//
//  AcademicOverview.swift
//  ChristUni
//
//  Hero summary for Academic Progression (values mirrored in mock for clarity).
//

import Foundation

struct AcademicOverview: Sendable, Codable {
    /// Cumulative GPA on a 4.0 scale (simple mean of term GPAs in mock data).
    var cumulativeGPA: Double
    var overallPercentage: Double
}
