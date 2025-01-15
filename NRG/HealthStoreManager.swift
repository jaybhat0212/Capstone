//
//  HealthStoreManager.swift
//  NRG
//
//  Created by Jay Bhatasana on 2024-07-19.
//

import HealthKit
import Combine

class HealthStoreManager: ObservableObject {
    let healthStore = HKHealthStore()

    @Published var steps: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var bodyWeight: Double = 0.0
    @Published var restingVO2: Double = 0.0
    @Published var heartRateVariability: Double = 0.0
    @Published var elevationChange: Double = 0.0

    init() {
        checkAuthorization()
    }

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
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
        ]

        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { [weak self] (success, error) in
            if success {
                self?.fetchHealthData()
            } else {
                print("HealthKit authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }

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

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] (query, result, error) in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps = \(String(describing: error?.localizedDescription))")
                return
            }

            let steps = sum.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async {
                self?.steps = steps
            }
        }

        healthStore.execute(query)
    }

    func fetchSpeed() {
        let speedType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: speedType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] (query, result, error) in
            guard let result = result, let avg = result.averageQuantity() else {
                print("Failed to fetch speed = \(String(describing: error?.localizedDescription))")
                return
            }

            let speed = avg.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second()))
            DispatchQueue.main.async {
                self?.speed = speed
            }
        }

        healthStore.execute(query)
    }

    func fetchBodyWeight() {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] (query, results, error) in
            guard let results = results, let sample = results.first as? HKQuantitySample else {
                print("Failed to fetch body weight = \(String(describing: error?.localizedDescription))")
                return
            }

            let weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            DispatchQueue.main.async {
                self?.bodyWeight = weight
            }
        }

        healthStore.execute(query)
    }

    func fetchRestingVO2() {
        let vo2Type = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: vo2Type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] (query, results, error) in
            guard let results = results, let sample = results.first as? HKQuantitySample else {
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
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] (query, results, error) in
            guard let results = results, let sample = results.first as? HKQuantitySample else {
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

        let query = HKStatisticsQuery(quantityType: elevationType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] (query, result, error) in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch elevation change = \(String(describing: error?.localizedDescription))")
                return
            }

            let elevationChange = sum.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async {
                self?.elevationChange = elevationChange
            }
        }

        healthStore.execute(query)
    }
}
