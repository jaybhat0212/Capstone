//
//  HealthManager.swift
//  NRG
//
//  Handles HealthKit permissions and fetching of basic metrics like VO2, body mass.
//
import HealthKit

class HealthManager {
    let healthStore = HKHealthStore()
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        // We read VO2Max, BodyMass, HRV, etc. No writes for now.
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)! // optional if you want direct HK distance
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, _ in
            completion(success)
        }
    }
    
    // Generic fetch for latest data sample
    func fetchLatestData(for identifier: HKQuantityTypeIdentifier,
                         unit: HKUnit,
                         completion: @escaping (Double?) -> Void) {
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: now),
                                                    end: now,
                                                    options: .strictStartDate)
        
        // We only retrieve the most recent for the day
        let query = HKStatisticsQuery(quantityType: quantityType,
                                      quantitySamplePredicate: predicate,
                                      options: .mostRecent) { _, result, _ in
            if let quantity = result?.mostRecentQuantity() {
                completion(quantity.doubleValue(for: unit))
            } else {
                completion(nil)
            }
        }
        healthStore.execute(query)
    }
}
