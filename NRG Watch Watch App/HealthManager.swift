import HealthKit
import WatchConnectivity
import SwiftUI

class HealthManager: NSObject, ObservableObject, WCSessionDelegate {
    let healthStore = HKHealthStore()

    @Published var phoneGelCalories: Int = 75
    @Published var bodyMass: Double = 70.0  // Default fallback in kg

    override init() {
        super.init()
        setupWatchConnectivity()
        requestDataFromPhone()
    }

    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("Watch HealthKit auth error: \(error.localizedDescription)")
            }
            completion(success)
        }
    }
    
    func requestDataFromPhone() {
        // Make sure the watch session is valid and reachable
        let session = WCSession.default
        guard session.isReachable else {
            print("Session not reachable")
            return
        }

        // Ask the phone for updated data
        let message = ["requestData": true]
        session.sendMessage(message, replyHandler: { response in
            // Parse the phone’s response (happens immediately)
            if let newCals = response["gelCalories"] as? Int {
                DispatchQueue.main.async {
                    self.phoneGelCalories = newCals
                }
            }
            if let newWeight = response["weight"] as? Double {
                DispatchQueue.main.async {
                    // If you also store that on watch side, handle here
                    // e.g. self.phoneWeight = newWeight
                }
            }
        }, errorHandler: { error in
            print("Failed to request data from phone: \(error.localizedDescription)")
        })
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let newCals = message["gelCalories"] as? Int {
                self.phoneGelCalories = newCals
                print("Watch received gelCalories from phone: \(newCals)")
            }
            if let newWeight = message["weight"] as? Double {
                self.bodyMass = newWeight
                print("Watch received weight from phone: \(newWeight) kg")
            }
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        // Handle session activation results if needed
    }
}
