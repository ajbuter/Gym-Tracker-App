//
//  GymTrackerApp.swift
//  Lift App
//
//  Created by Aiden Buter on 11/6/25.
//

import SwiftUI

@main
struct GymTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppState()) // inject your app state
        }
    }
}
