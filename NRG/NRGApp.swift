//
//  NRGApp.swift
//  NRG
//
//  Created by Jay Bhatasana on 2024-07-19.
//

import SwiftUI
import HealthKit

@main
struct NRGApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(HealthStoreManager())
        }
    }
}
