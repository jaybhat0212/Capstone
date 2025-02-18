//
//  MotionManager.swift
//  NRG
//
//  Tracks distance, speed, floors ascended/descended, and HRV in real-time.
//  1) Use CMPedometer for distance and floorsAscended/floorsDescended.
//  2) Use HKAnchoredObjectQuery for heartRateVariabilitySDNN.
//
//  We'll convert 'currentPace' to speed (m/s) if we wish, but also
//  rely on 'data.distance' for total distance.
//
import CoreMotion
import HealthKit

class MotionManager {
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    
    // For HR Variability
    private var hrvQuery: HKAnchoredObjectQuery?
    
    /// Start collecting data from pedometer & HealthKit
    /// - Parameter completion: distance(m), speed(m/s), floorsAscDesc(Double), hrv(Double)
    func startUpdates(completion: @escaping (Double?, Double?, Double?, Double?) -> Void) {
        // Check if pedometer features are available
        guard CMPedometer.isDistanceAvailable(),
              CMPedometer.isFloorCountingAvailable() else {
            print("Pedometer features not available.")
            return
        }
        
        // Start pedometer from now
        pedometer.startUpdates(from: Date()) { data, _ in
            // Distance is total in meters since start
            let distance = data?.distance?.doubleValue
            
            // currentPace = seconds per meter (if available)
            // speed = 1 / pace => m/s
            var speedMS: Double?
            if let pace = data?.currentPace?.doubleValue, pace > 0 {
                speedMS = 1.0 / pace
            }
            
            // floorsAscended - floorsDescended
            let floorsAscDesc = Double((data?.floorsAscended?.intValue ?? 0)
                                     - (data?.floorsDescended?.intValue ?? 0))
            
            // For now, pass hrv as nil here; we'll fill it from HK query below
            completion(distance, speedMS, floorsAscDesc, nil)
        }
        
        // HRV anchored query
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let query = HKAnchoredObjectQuery(type: hrvType,
                                          predicate: nil,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
            if let hrvSample = samples?.last as? HKQuantitySample {
                let hrvValue = hrvSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                completion(nil, nil, nil, hrvValue)
            }
        }
        
        // Also listen for new HRV samples in real time
        query.updateHandler = { _, samples, _, _, _ in
            if let hrvSample = samples?.last as? HKQuantitySample {
                let hrvValue = hrvSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                completion(nil, nil, nil, hrvValue)
            }
        }
        
        healthStore.execute(query)
        hrvQuery = query
    }
    
    /// Stop pedometer and anchored queries
    func stopUpdates() {
        pedometer.stopUpdates()
        if let query = hrvQuery {
            healthStore.stop(query)
        }
    }
}
