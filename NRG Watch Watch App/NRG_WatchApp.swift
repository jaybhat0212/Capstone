//
//  NRG_Watch_Watch_AppApp.swift
//  NRG Watch Watch App
//
//  Created by Jay Bhatasana on 2025-01-15.
//
import SwiftUI

@main
struct NRG_Watch_Watch_AppApp: App {
    @StateObject private var healthManager = HealthManager()

    var body: some Scene {
        WindowGroup {
            ContentView(healthManager: healthManager)
        }
    }
}

