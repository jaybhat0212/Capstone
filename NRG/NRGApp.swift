//
//  NRGApp.swift
//  NRG
//
//  Created by Jay Bhatasana on 2024-07-19.
//

import SwiftUI

@main
struct NRGApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
