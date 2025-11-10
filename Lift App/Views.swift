//
//  Views.swift
//  Lift App
//
//  Created by Aiden Buter on 11/6/25.
//


import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var appState = AppState()

    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(appState)
                .tabItem { Label("Home", systemImage: "house") }

            WorkoutsListView()
                .environmentObject(appState)
                .tabItem { Label("Workouts", systemImage: "list.bullet") }

            PRsView()
                .environmentObject(appState)
                .tabItem { Label("PRs", systemImage: "flag") }

            HealthView()
                .environmentObject(appState)
                .tabItem { Label("Health", systemImage: "heart") }
        }
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Welcome to GymTracker")
                    .font(.title)

                if let latestPR = appState.prs.sorted(by: { $0.date > $1.date }).first {
                    Text("Latest PR: \(latestPR.exerciseName) - \(String(format: "%.1f", latestPR.bestweight)) lbs")
                } else {
                    Text("No PRs yet — log a set to start tracking")
                }

                if let wc = appState.weeklyChange() {
                    Text("Weekly weight change: \(String(format: "%+.2f", wc)) lbs")
                }
                if let mc = appState.monthlyChange() {
                    Text("Monthly weight change: \(String(format: "%+.2f", mc)) lbs")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Workouts List + Builder

struct WorkoutsListView: View {
    @EnvironmentObject var appState: AppState
    @State private var newName = ""

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("New workout name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                    Button("Create") {
                        appState.createWorkout(name: newName.isEmpty ? "Workout" : newName)
                        newName = ""
                    }
                }
                .padding()

                List {
                    ForEach(appState.workouts) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: binding(for: workout))) {
                            VStack(alignment: .leading) {
                                Text(workout.name)
                                Text(workout.date, style: .date).font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
        }
    }

    // Helper to get binding to workout inside appState.workouts
    func binding(for workout: Workout) -> Binding<Workout> {
        guard let idx = appState.workouts.firstIndex(where: { $0.id == workout.id }) else {
            fatalError("Workout not found")
        }
        return $appState.workouts[idx]
    }
}

struct WorkoutDetailView: View {
    @Binding var workout: Workout
    @EnvironmentObject var appState: AppState
    @State private var exerciseName = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Exercise name", text: $exerciseName)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let ex = Exercise(name: exerciseName)
                    workout.exercises.append(ex)
                    exerciseName = ""
                }
            }
            .padding()

            List {
                ForEach(workout.exercises) { exercise in
                    NavigationLink(destination: ExerciseSessionView(exercise: binding(for: exercise), workoutId: workout.id)) {
                        Text(exercise.name)
                    }
                }
            }
        }
        .navigationTitle(workout.name)
    }

    func binding(for exercise: Exercise) -> Binding<Exercise> {
        guard let wIdx = appState.workouts.firstIndex(where: { $0.id == workout.id }) else { fatalError() }
        guard let exIdx = appState.workouts[wIdx].exercises.firstIndex(where: { $0.id == exercise.id }) else { fatalError() }
        return $appState.workouts[wIdx].exercises[exIdx]
    }
}

// MARK: - Exercise Session + Rest Timer

struct ExerciseSessionView: View {
    @Binding var exercise: Exercise
    @EnvironmentObject var appState: AppState

    // User input fields for new set
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var restSeconds: Int = 90

    // Timer state
    @State private var remaining: Int = 0
    @State private var timerActive = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var workoutId: UUID

    var body: some View {
        VStack(spacing: 12) {
            Form {
                Section(header: Text("Log a set")) {
                    TextField("Weight (lbs)", text: $weightText)
                        .keyboardType(.decimalPad)
                    TextField("Reps", text: $repsText)
                        .keyboardType(.numberPad)
                    Stepper("Rest: \(restSeconds) sec", value: $restSeconds, in: 10...600, step: 5)
                    HStack {
                        Button("Add Set") {
                            addSetAndStartRest()
                        }
                        Spacer()
                        Button("Add without rest") {
                            addSet() // no timer
                        }
                    }
                }

                Section(header: Text("Sets")) {
                    ForEach(exercise.sets) { set in
                        HStack {
                            Text("\(String(format: "%.1f", set.weightlb)) lbs x \(set.reps)")
                            Spacer()
                            Text(set.timestamp, style: .time).font(.caption)
                        }
                    }
                }

                Section(header: Text("Rest Timer")) {
                    if timerActive {
                        Text("Remaining: \(remaining) sec")
                            .font(.headline)
                    } else {
                        Text("Timer inactive")
                    }
                    Button(timerActive ? "Stop" : "Start") {
                        toggleTimer()
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            guard timerActive else { return }
            if remaining > 0 {
                remaining -= 1
            } else {
                timerActive = false
            }
        }
        .navigationTitle(exercise.name)
        .padding()
    }

    func addSet() {
        guard let lbs = Double(weightText), let reps = Int(repsText) else { return }
        let set = SetEntry(weightlb: lbs, reps: reps)
        // also inform appState so PRs update and persistence triggers
        appState.logSet(exerciseId: exercise.id, set: set)
        weightText = ""
        repsText = ""
    }

    func addSetAndStartRest() {
        addSet()
        remaining = restSeconds
        timerActive = true
    }

    func toggleTimer() {
        timerActive.toggle()
        if timerActive && remaining == 0 { remaining = restSeconds }
    }
}

// MARK: - PRs View (simple list; for charts, you'd use Swift Charts on iOS 16+)

struct PRsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            List {
                ForEach(appState.prs.sorted(by: { $0.bestweight > $1.bestweight })) { pr in
                    VStack(alignment: .leading) {
                        Text(pr.exerciseName).font(.headline)
                        Text("Best: \(String(format: "%.1f", pr.bestweight)) lbs — \(pr.date, style: .date)")
                    }
                }
            }
            .navigationTitle("Personal Records")
        }
    }
}

// MARK: - Health View

struct HealthView: View {
    @EnvironmentObject var appState: AppState
    @State private var weightText = ""
    @State private var heightText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Form {
                    Section(header: Text("Log weight / height")) {
                        TextField("Weight (lbs)", text: $weightText).keyboardType(.decimalPad)
                        TextField("Height (inches) - optional", text: $heightText).keyboardType(.decimalPad)
                        Button("Log") {
                            guard let w = Double(weightText) else { return }
                            let h = Double(heightText)
                            appState.logWeight(weightlbs: w, heightCm: h)
                            weightText = ""
                            heightText = ""
                        }
                    }

                    Section(header: Text("Latest metrics")) {
                        if let latest = appState.metrics.last {
                            Text("Weight: \(String(format: "%.1f", latest.weightlbs)) lbs")
                            if let h = latest.heightCm { Text("Height: \(String(format: "%.1f", h)) cm") }
                        } else {
                            Text("No metrics logged yet")
                        }
                    }

                    Section(header: Text("Trends")) {
                        if let w = appState.weeklyChange() {
                            Text("Weekly change: \(String(format: "%+.2f", w)) lbs")
                        }
                        if let m = appState.monthlyChange() {
                            Text("Monthly change: \(String(format: "%+.2f", m)) lbs")
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Health")
        }
    }
}
