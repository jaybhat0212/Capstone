import CoreMotion
import HealthKit

class MotionManager {
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    
    // Queries for HRV, Heart Rate, and VO2 Max
    private var hrvQuery: HKAnchoredObjectQuery?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var vo2Query: HKAnchoredObjectQuery?
    
    // Store the latest values so we can always send complete data back
    private var latestDistance: Double = 0.0
    private var latestSpeed: Double = 0.0
    private var latestFloorsAscDesc: Double = 0.0
    private var latestHRV: Double?
    private var latestHR: Double?
    private var latestVO2Max: Double?
    
    // The completion closure we’ll call any time something updates
    // Includes VO2 Max as the 6th parameter now
    private var updateCompletion: ((Double?, Double?, Double?, Double?, Double?, Double?) -> Void)?
    
    /// Starts pedometer and HealthKit queries for real-time updates.
    /// - Parameter completion: Receives updated values (distance, speed, floorsAscDesc, hrv, hr, vo2Max).
    func startUpdates(completion: @escaping (Double?, Double?, Double?, Double?, Double?, Double?) -> Void) {
        self.updateCompletion = completion
        
        // 1) Start pedometer for distance, floors, etc.
        guard CMPedometer.isDistanceAvailable() && CMPedometer.isFloorCountingAvailable() else {
            print("Pedometer features not available.")
            return
        }
        
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                print("MotionManager pedometer error: \(error.localizedDescription)")
            }
            
            // Distance
            if let dist = data?.distance?.doubleValue {
                self.latestDistance = dist
            }
            
            // Speed in m/s (1 ÷ currentPace)
            if let pace = data?.currentPace?.doubleValue, pace > 0 {
                self.latestSpeed = 1.0 / pace
            }
            
            // Floors ascended - floors descended
            let asc = data?.floorsAscended?.intValue ?? 0
            let desc = data?.floorsDescended?.intValue ?? 0
            self.latestFloorsAscDesc = Double(asc - desc)
            
            self.sendUpdate()
        }
        
        // 2) HRV anchored query
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let hrvQuery = HKAnchoredObjectQuery(type: hrvType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) {
            [weak self] _, samples, _, _, _ in
            guard let self = self else { return }
            if let sample = samples?.last as? HKQuantitySample {
                self.latestHRV = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                self.sendUpdate()
            }
        }
        
        hrvQuery.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let self = self else { return }
            if let sample = samples?.last as? HKQuantitySample {
                self.latestHRV = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                self.sendUpdate()
            }
        }
        healthStore.execute(hrvQuery)
        self.hrvQuery = hrvQuery
        
        // 3) Heart Rate anchored query
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let hrQuery = HKAnchoredObjectQuery(type: hrType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) {
            [weak self] _, samples, _, _, _ in
            guard let self = self else { return }
            if let sample = samples?.last as? HKQuantitySample {
                self.latestHR = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self.sendUpdate()
            }
        }
        
        hrQuery.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let self = self else { return }
            if let sample = samples?.last as? HKQuantitySample {
                self.latestHR = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self.sendUpdate()
            }
        }
        healthStore.execute(hrQuery)
        self.heartRateQuery = hrQuery
        
        // 4) VO2 Max anchored query
        guard let vo2Type = HKObjectType.quantityType(forIdentifier: .vo2Max) else { return }
        
        let vo2Query = HKAnchoredObjectQuery(type: vo2Type, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) {
            [weak self] _, samples, _, _, _ in
            guard let self = self else { return }
            if let sample = samples?.last as? HKQuantitySample {
                // Convert to ml/kg*min
                let vo2Value = sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
                self.latestVO2Max = vo2Value
                self.sendUpdate()
            }
        }
        
        vo2Query.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let self = self else { return }
            if let sample = samples?.last as? HKQuantitySample {
                let vo2Value = sample.quantity.doubleValue(for: HKUnit(from: "ml/kg*min"))
                self.latestVO2Max = vo2Value
                self.sendUpdate()
            }
        }
        healthStore.execute(vo2Query)
        self.vo2Query = vo2Query
    }
    
    /// Stops pedometer and queries.
    func stopUpdates() {
        pedometer.stopUpdates()
        
        if let hrvQ = hrvQuery { healthStore.stop(hrvQ) }
        if let hrQ = heartRateQuery { healthStore.stop(hrQ) }
        if let vo2Q = vo2Query { healthStore.stop(vo2Q) }
        
        // Reset everything
        latestDistance = 0
        latestSpeed = 0
        latestFloorsAscDesc = 0
        latestHRV = nil
        latestHR = nil
        latestVO2Max = nil
    }
    
    /// Utility to call the completion with all current data
    private func sendUpdate() {
        // Now includes latestVO2Max as 6th param
        updateCompletion?(
            latestDistance,
            latestSpeed,
            latestFloorsAscDesc,
            latestHRV,
            latestHR,
            latestVO2Max
        )
    }
}
