//
//  HealthManager.swift
//  NRG
//
//  Handles HealthKit permissions and fetching of basic metrics like VO₂ Max, body mass, HRV, and heart rate.
import HealthKit

class HealthManager {
    let healthStore = HKHealthStore()
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
            completion(success)
        }
    }
    
    /// Fetch the latest sample data.
    func fetchLatestData(for identifier: HKQuantityTypeIdentifier,
                         unit: HKUnit,
                         completion: @escaping (Double?) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: now)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let sampleQuery = HKSampleQuery(sampleType: quantityType,
                                        predicate: predicate,
                                        limit: 1,
                                        sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("❌ \(identifier.rawValue) query error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let samples = samples as? [HKQuantitySample], let latestSample = samples.first else {
                print("❌ No \(identifier.rawValue) samples found. Using default value.")
                
                let defaultValue: Double? = (identifier == .vo2Max) ? 35.0 : nil  // Default VO₂ Max = 35 ml/kg/min
                completion(defaultValue)
                return
            }

            let retrievedValue = latestSample.quantity.doubleValue(for: unit)
            print("✅ Retrieved \(identifier.rawValue): \(retrievedValue) \(unit)")
            completion(retrievedValue)
        }

        healthStore.execute(sampleQuery)
    }

    /// Fetches all major health metrics at once.
    func fetchAllHealthMetrics(completion: @escaping (Double?, Double?, Double?, Double?) -> Void) {
        let identifiers: [(HKQuantityTypeIdentifier, HKUnit)] = [
            (.vo2Max, HKUnit(from: "ml/kg*min")),
            (.bodyMass, HKUnit.gramUnit(with: .kilo)),
            (.heartRateVariabilitySDNN, HKUnit.secondUnit(with: .milli)),
            (.heartRate, HKUnit.count().unitDivided(by: HKUnit.minute()))
        ]
        
        var results: [HKQuantityTypeIdentifier: Double] = [:]
        let group = DispatchGroup()
        
        for (identifier, unit) in identifiers {
            group.enter()
            
            guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
                print("❌ HealthKit: \(identifier.rawValue) is not available.")
                group.leave()
                continue
            }

            let now = Date()
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let sampleQuery = HKSampleQuery(sampleType: quantityType,
                                            predicate: predicate,
                                            limit: 1,
                                            sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    print("❌ \(identifier.rawValue) query error: \(error.localizedDescription)")
                } else if let samples = samples as? [HKQuantitySample], let latestSample = samples.first {
                    let value = latestSample.quantity.doubleValue(for: unit)
                    results[identifier] = value
                    print("✅ \(identifier.rawValue): \(value) \(unit)")
                } else {
                    print("❌ No \(identifier.rawValue) samples found.")
                }
                group.leave()
            }
            healthStore.execute(sampleQuery)
        }

        group.notify(queue: .main) {
            let vo2 = results[.vo2Max]
            let bodyMass = results[.bodyMass]
            let hrv = results[.heartRateVariabilitySDNN]
            let heartRate = results[.heartRate]

            print("""
            🔹 HealthKit Data Retrieved:
            - Body Mass: \(bodyMass ?? 0) kg
            - HRV: \(hrv ?? 0) ms
            - VO₂ Max: \(vo2 ?? 0) ml/kg/min
            - Heart Rate: \(heartRate ?? 0) bpm
            """)

            completion(vo2, bodyMass, hrv, heartRate)
        }
    }
}
