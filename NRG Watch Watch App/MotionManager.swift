import CoreMotion
import HealthKit

class MotionManager {
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    
    private var totalDistance: Double = 0
    private var hrvQuery: HKAnchoredObjectQuery?

    func startUpdates(completion: @escaping (Double?, Double?, Double?, Double?, Double?) -> Void) {
        guard CMPedometer.isDistanceAvailable(),
              CMPedometer.isFloorCountingAvailable() else {
            print("Pedometer features not available.")
            return
        }

        pedometer.startUpdates(from: Date()) { data, _ in
            let newDistance = data?.distance?.doubleValue ?? 0
            self.totalDistance += newDistance
            
            let speedMS: Double? = {
                if let pace = data?.currentPace?.doubleValue, pace > 0 {
                    return 1.0 / pace
                }
                return nil
            }()

            let floorsAscDesc = Double((data?.floorsAscended?.intValue ?? 0) - (data?.floorsDescended?.intValue ?? 0))
            
            completion(self.totalDistance, speedMS, floorsAscDesc, nil, nil)
        }
    }
    
    func stopUpdates() {
        pedometer.stopUpdates()
    }
}
