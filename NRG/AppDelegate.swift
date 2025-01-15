//
//  AppDelegate.swift
//  NRG
//
//  Created by Jay Bhatasana on 2024-07-19.
//

import UIKit
import HealthKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let healthStore = HKHealthStore()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        requestHealthKitAuthorization()
        return true
    }

    private func requestHealthKitAuthorization() {
        if HKHealthStore.isHealthDataAvailable() {
            let healthKitTypes: Set = [
                HKObjectType.quantityType(forIdentifier: .stepCount)!
            ]

            healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { (success, error) in
                if !success {
                    print("HealthKit authorization failed: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
}
