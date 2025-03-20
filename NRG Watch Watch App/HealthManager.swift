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
        guard WCSession.default.isReachable else {
            print("❌ Watch cannot reach phone")
            return
        }
        
        let message = ["requestData": true]  // Request data from phone
        WCSession.default.sendMessage(message, replyHandler: { response in
            DispatchQueue.main.async {
                if let gelCals = response["gelCalories"] as? Int {
                    self.phoneGelCalories = gelCals
                    print("📥 Watch received gelCalories: \(gelCals) cal")
                }
                if let weight = response["weight"] as? Double {
                    self.bodyMass = weight
                    print("📥 Watch received bodyMass: \(weight) kg")
                }
            }
        }, errorHandler: { error in
            print("❌ Failed to request data from phone: \(error.localizedDescription)")
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
