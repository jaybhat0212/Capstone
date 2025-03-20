//
//  PhoneHealthStoreManager.swift
//  NRG
//
//  Created by Jay Bhatasana on 2024-07-19.
//

import HealthKit
import Combine
import WatchConnectivity

class HealthStoreManager: NSObject, ObservableObject, WCSessionDelegate {
    let healthStore = HKHealthStore()

    @Published var steps: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var bodyWeight: Double = 0.0  // Weight in kg
    @Published var restingVO2: Double = 0.0
    @Published var heartRateVariability: Double = 0.0
    @Published var elevationChange: Double = 0.0
    @Published var gelCalories: Int = 75

    private var session: WCSession?

    override init() {
        super.init()
        checkAuthorization()
        setupWatchConnectivity()
    }

    // MARK: - Watch Connectivity (on iPhone)
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendWeightToWatch() {
        guard let session = session, session.isReachable else { return }
        let message = ["weight": bodyWeight]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send weight: \(error.localizedDescription)")
        }
    }

    func updateWeightOnPhone(newWeightInKg: Double) {
        self.bodyWeight = newWeightInKg
        sendWeightToWatch()
    }

    // MARK: - HealthKit Authorization
    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }

        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .walkingSpeed)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { [weak self] success, error in
            if success {
                self?.fetchHealthData()
            } else {
                print("HealthKit authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }

    // MARK: - Fetch from HealthKit
    func fetchHealthData() {
        fetchStepCount()
        fetchSpeed()
        fetchBodyWeight()
        fetchRestingVO2()
        fetchHeartRateVariability()
        fetchElevationChange()
    }

    func fetchStepCount() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps = \(String(describing: error?.localizedDescription))")
                return
            }
            DispatchQueue.main.async {
                self?.steps = sum.doubleValue(for: HKUnit.count())
            }
        }
        healthStore.execute(query)
    }

    func fetchSpeed() {
        let speedType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: speedType,
                                      quantitySamplePredicate: predicate,
                                      options: .discreteAverage) { [weak self] _, result, error in
            guard let result = result, let avg = result.averageQuantity() else {
                print("Failed to fetch speed = \(String(describing: error?.localizedDescription))")
                return
            }
            let speed = avg.doubleValue(for: HKUnit.meter().unitDivided(by: .second()))
            DispatchQueue.main.async {
                self?.speed = speed
            }
        }
        healthStore.execute(query)
    }

    func fetchBodyWeight() {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType,
                                  predicate: nil,
                                  limit: 1,
                                  sortDescriptors: [sortDescriptor]) { [weak self] _, results, error in
            guard let results = results,
                  let sample = results.first as? HKQuantitySample else {
                print("Failed to fetch body weight = \(String(describing: error?.localizedDescription))")
                return
            }
            let kg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            DispatchQueue.main.async {
                self?.bodyWeight = kg
                // Immediately send the updated weight to watch
                self?.sendWeightToWatch()
            }
        }
        healthStore.execute(query)
    }

    func fetchRestingVO2() {
        let vo2Type = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: vo2Type,
                                  predicate: nil,
                                  limit: 1,
                                  sortDescriptors: [sortDescriptor]) { [weak self] _, results, error in
            guard let results = results,
                  let sample = results.first as? HKQuantitySample else {
                print("Failed to fetch resting VO2 = \(String(describing: error?.localizedDescription))")
                return
            }
            let vo2 = sample.quantity.doubleValue(for: HKUnit(from: "ml/(kg*min)"))
            DispatchQueue.main.async {
                self?.restingVO2 = vo2
            }
        }
        healthStore.execute(query)
    }

    func fetchHeartRateVariability() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrvType,
                                  predicate: nil,
                                  limit: 1,
                                  sortDescriptors: [sortDescriptor]) { [weak self] _, results, error in
            guard let results = results,
                  let sample = results.first as? HKQuantitySample else {
                print("Failed to fetch heart rate variability = \(String(describing: error?.localizedDescription))")
                return
            }
            let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            DispatchQueue.main.async {
                self?.heartRateVariability = hrv
            }
        }
        healthStore.execute(query)
    }

    func fetchElevationChange() {
        let elevationType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: elevationType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch elevation change = \(String(describing: error?.localizedDescription))")
                return
            }
            DispatchQueue.main.async {
                self?.elevationChange = sum.doubleValue(for: HKUnit.count())
            }
        }
        healthStore.execute(query)
    }

    // MARK: - WCSessionDelegate Methods (REQUIRED on iPhone)
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?)
    {
        // Usually you can leave this empty, or handle errors if needed
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Required method; empty implementation is OK
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Required method; re-activate if needed
        WCSession.default.activate()
    }

    // MARK: - Receiving watch messages
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void)
    {
        if message["requestData"] as? Bool == true {
            let response: [String: Any] = [
                "gelCalories": self.gelCalories,
                "weight": self.bodyWeight
            ]
            replyHandler(response)
            print("📤 Phone sent gelCalories: \(gelCalories) cal, weight: \(bodyWeight) kg")
        }
    }
}
