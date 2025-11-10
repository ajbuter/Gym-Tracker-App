//  Untitled.swift
//  Lift App
//
//  Created by Aiden Buter on 11/6/25.
//

//
// =========================
// File: Models.swift
// =========================

import Foundation
import Combine

// MARK: - Models

// A single set performed during a workout
struct SetEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var weightlb: Double
    var reps: Int
    var timestamp: Date = Date()
}

// An exercise in a routine or performed during a workout
class Exercise: Identifiable, ObservableObject, Codable {
    var id: UUID = UUID()
    @Published var name: String
    @Published var sets: [SetEntry] = []

    init(id: UUID = UUID(), name: String, sets: [SetEntry] = []) {
        self.id = id
        self.name = name
        self.sets = sets
    }

    // MARK: Codable support
    enum CodingKeys: CodingKey { case id, name, sets }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sets = try container.decode([SetEntry].self, forKey: .sets)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sets, forKey: .sets)
    }
}


// A workout session contains multiple exercises
struct Workout: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var name: String = "Workout"
    var exercises: [Exercise] = []
}

// Body metrics for Health (height stored once, weight logged over time)
struct BodyMetric: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var weightlbs: Double
    var heightCm: Double? = nil // optional, only set when changed
}

// A simple PR (personal record) representation
struct PRRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var exerciseName: String
    var bestweight: Double
    var date: Date
}

//
