import CoreMotion
import HealthKit

class MotionManager {
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    
    // Query for HRV
    private var hrvQuery: HKAnchoredObjectQuery?
    // Now we also track heart rate
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    // Baseline readings for distance and floors, so we only get the changes
    private var initialDistance: Double?
    private var initialFloorsAscended: Int?
    private var initialFloorsDescended: Int?

    /// - Parameter completion: (distance in meters, speed in m/s, floorsAscDesc, hrv in ms, heartRate in BPM)
    func startUpdates(completion: @escaping (Double?, Double?, Double?, Double?, Double?) -> Void) {
        guard CMPedometer.isDistanceAvailable(),
              CMPedometer.isFloorCountingAvailable()
        else {
            print("Pedometer features not available.")
            return
        }
        
        // Start pedometer for distance, floors, etc.
        pedometer.startUpdates(from: Date()) { data, error in
            if let error = error {
                print("MotionManager pedometer error: \(error.localizedDescription)")
            }
            
            // Raw distance
            let rawDistance = data?.distance?.doubleValue
            
            var distance: Double? = nil
            if let dist = rawDistance {
                if self.initialDistance == nil {
                    self.initialDistance = dist
                }
                distance = max(0, dist - (self.initialDistance ?? 0))
            }
            
            // speed = 1 ÷ currentPace (m/s)
            var speedMS: Double?
            if let pace = data?.currentPace?.doubleValue, pace > 0 {
                speedMS = 1.0 / pace
            }
            
            let asc = data?.floorsAscended?.intValue ?? 0
            let desc = data?.floorsDescended?.intValue ?? 0
            
            if self.initialFloorsAscended == nil {
                self.initialFloorsAscended = asc
            }
            if self.initialFloorsDescended == nil {
                self.initialFloorsDescended = desc
            }
            
            let ascDelta = asc - (self.initialFloorsAscended ?? 0)
            let descDelta = desc - (self.initialFloorsDescended ?? 0)
            let floorsAscDesc = Double(ascDelta - descDelta)
            
            // For the anchored queries, we pass nil here (they update in their own query).
            completion(distance, speedMS, floorsAscDesc, nil, nil)
        }
        
        // ---------------------------------------------------------------------
        // Heart Rate Variability anchored query
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let hrvQuery = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, _, _ in
            if let hrvSample = samples?.last as? HKQuantitySample {
                let hrvValue = hrvSample.quantity.doubleValue(for: .secondUnit(with: .milli))
                completion(nil, nil, nil, hrvValue, nil)
            }
        }
        
        hrvQuery.updateHandler = { _, samples, _, _, _ in
            if let hrvSample = samples?.last as? HKQuantitySample {
                let hrvValue = hrvSample.quantity.doubleValue(for: .secondUnit(with: .milli))
                completion(nil, nil, nil, hrvValue, nil)
            }
        }
        
        healthStore.execute(hrvQuery)
        self.hrvQuery = hrvQuery
        
        // ---------------------------------------------------------------------
        // Heart Rate anchored query
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let hrQuery = HKAnchoredObjectQuery(
            type: hrType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, _, _ in
            if let hrSample = samples?.last as? HKQuantitySample {
                // Heart rate is usually stored in "count/min" units
                let hrValue = hrSample.quantity.doubleValue(for: .init(from: "count/min"))
                completion(nil, nil, nil, nil, hrValue)
            }
        }
        
        hrQuery.updateHandler = { _, samples, _, _, _ in
            if let hrSample = samples?.last as? HKQuantitySample {
                let hrValue = hrSample.quantity.doubleValue(for: .init(from: "count/min"))
                completion(nil, nil, nil, nil, hrValue)
            }
        }
        
        healthStore.execute(hrQuery)
        self.heartRateQuery = hrQuery
    }
    
    func stopUpdates() {
        pedometer.stopUpdates()
        if let query = hrvQuery {
            healthStore.stop(query)
        }
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        
        // Reset baselines
        initialDistance = nil
        initialFloorsAscended = nil
        initialFloorsDescended = nil
    }
}
