//
//  WatchHealthManager.swift
//  NRG Watch Watch App
//
//  Created by ...
//

import HealthKit
import WatchConnectivity
import SwiftUI

class HealthManager: NSObject, ObservableObject, WCSessionDelegate {
    let healthStore = HKHealthStore()

    // Store phone-synced data, e.g. gel calories
    @Published var phoneGelCalories: Int = 75

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - WatchConnectivity
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - HealthKit Request
    /// Call this from your ContentView onAppear to request read access on watch.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        // Decide which types you want to read from watch’s local HealthKit store:
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!
            // Add others if needed, e.g. HRV, distanceWalkingRunning, etc.
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("Watch HealthKit auth error: \(error.localizedDescription)")
            }
            completion(success)
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // If the phone sends 'gelCalories', store it:
        if let newCals = message["gelCalories"] as? Int {
            DispatchQueue.main.async {
                self.phoneGelCalories = newCals
                print("Watch got new gelCalories from phone: \(newCals)")
            }
        }

        // If you also handle weight, HRV, VO2, etc., you'd process them here as well.
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        // If needed, handle session activation results
    }

    // Note: watchOS does not allow sessionDidBecomeInactive / sessionDidDeactivate overrides
}
