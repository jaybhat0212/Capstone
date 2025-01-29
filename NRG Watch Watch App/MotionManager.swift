//
//  MotionManager.swift
//  NRG
//
//  Created by Jay Bhatasana on 2025-01-19.
//


import CoreMotion
import HealthKit

class MotionManager {
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?

    func startUpdates(completion: @escaping (Double?, Double?, Double?) -> Void) {
        // Start Pedometer for speed and gradient
        guard CMPedometer.isPaceAvailable(), CMPedometer.isFloorCountingAvailable() else {
            print("Pedometer features not available.")
            return
        }

        pedometer.startUpdates(from: Date()) { data, _ in
            let speed = data?.currentPace?.doubleValue
            let gradient = data?.floorsAscended?.doubleValue ?? 0 - (data?.floorsDescended?.doubleValue ?? 0)
            completion(speed, gradient, nil)
        }

        // Start Heart Rate Monitoring
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
            if let heartRateSample = samples?.last as? HKQuantitySample {
                let heartRate = heartRateSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                completion(nil, nil, heartRate)
            }
        }
        healthStore.execute(query)
        heartRateQuery = query
    }

    func stopUpdates() {
        pedometer.stopUpdates()
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
    }
}
