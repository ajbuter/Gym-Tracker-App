//
//  ViewModels.swift
//  Lift App
//
//  Created by Aiden Buter on 11/6/25.
//

import Foundation
import Combine

final class AppState: ObservableObject {
    // Published properties will update SwiftUI views automatically
    @Published var workouts: [Workout] = []
    @Published var metrics: [BodyMetric] = []
    @Published var prs: [PRRecord] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadAll()

        // Whenever these arrays change, we auto-save to disk
        $workouts
            .sink { [weak self] _ in try? self?.saveWorkouts() }
            .store(in: &cancellables)

        $metrics
            .sink { [weak self] _ in try? self?.saveMetrics() }
            .store(in: &cancellables)

        $prs
            .sink { [weak self] _ in try? self?.savePRs() }
            .store(in: &cancellables)
    }

    // MARK: Persistence wrappers
    private func loadAll() {
        do {
            if PersistenceManager.shared.exists(filename: "workouts.json") {
                self.workouts = try PersistenceManager.shared.load([Workout].self, filename: "workouts.json")
            }
            if PersistenceManager.shared.exists(filename: "metrics.json") {
                self.metrics = try PersistenceManager.shared.load([BodyMetric].self, filename: "metrics.json")
            }
            if PersistenceManager.shared.exists(filename: "prs.json") {
                self.prs = try PersistenceManager.shared.load([PRRecord].self, filename: "prs.json")
            }
        } catch {
            print("Failed to load: \(error)")
        }
    }

    private func saveWorkouts() throws {
        try PersistenceManager.shared.save(workouts, filename: "workouts.json")
    }
    private func saveMetrics() throws {
        try PersistenceManager.shared.save(metrics, filename: "metrics.json")
    }
    private func savePRs() throws {
        try PersistenceManager.shared.save(prs, filename: "prs.json")
    }

    // MARK: Business logic helpers
    func logSet(exerciseId: UUID, set: SetEntry) {
        guard let wIndex = workouts.firstIndex(where: { workout in
            workout.exercises.contains(where: { $0.id == exerciseId })
        }) else { return }

        // find exercise inside workout
        for exIndex in workouts[wIndex].exercises.indices {
            if workouts[wIndex].exercises[exIndex].id == exerciseId {
                workouts[wIndex].exercises[exIndex].sets.append(set)
                updatePRIfNeeded(exerciseName: workouts[wIndex].exercises[exIndex].name, candidateLbs: set.weightlb, date: set.timestamp)
                break
            }
        }
    }

    func updatePRIfNeeded(exerciseName: String, candidateLbs: Double, date: Date) {
        if let idx = prs.firstIndex(where: { $0.exerciseName == exerciseName }) {
            if candidateLbs > prs[idx].bestweight {
                prs[idx].bestweight = candidateLbs
                prs[idx].date = date
            }
        } else {
            let rec = PRRecord(exerciseName: exerciseName, bestweight: candidateLbs, date: date)
            prs.append(rec)
        }
    }

    // Add a new workout (empty)
    func createWorkout(name: String = "Workout") {
        workouts.insert(Workout(name: name), at: 0)
    }

    // Log a body metric
    func logWeight(weightlbs: Double, heightCm: Double? = nil) {
        var entry = BodyMetric(weightlbs: weightlbs)
        entry.heightCm = heightCm
        metrics.append(entry)
    }

    // Compute weekly change (lbs) between latest and 7 days ago average
    func weeklyChange() -> Double? {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let recent = metrics.filter { $0.date >= weekAgo }
        guard !recent.isEmpty else { return nil }
        let avgRecent = recent.map { $0.weightlbs }.reduce(0,+) / Double(recent.count)

        // find older entries 7-14 days ago
        let olderStart = Calendar.current.date(byAdding: .day, value: -14, to: now)!
        let older = metrics.filter { $0.date >= olderStart && $0.date < weekAgo }
        guard !older.isEmpty else { return nil }
        let avgOlder = older.map { $0.weightlbs }.reduce(0,+) / Double(older.count)
        return avgRecent - avgOlder
    }

    // Monthly change similar
    func monthlyChange() -> Double? {
        let now = Date()
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        let recent = metrics.filter { $0.date >= monthAgo }
        guard !recent.isEmpty else { return nil }
        let avgRecent = recent.map { $0.weightlbs }.reduce(0,+) / Double(recent.count)

        let olderStart = Calendar.current.date(byAdding: .month, value: -2, to: now)!
        let older = metrics.filter { $0.date >= olderStart && $0.date < monthAgo }
        guard !older.isEmpty else { return nil }
        let avgOlder = older.map { $0.weightlbs }.reduce(0,+) / Double(older.count)
        return avgRecent - avgOlder
    }
}
