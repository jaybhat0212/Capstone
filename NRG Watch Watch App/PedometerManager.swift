import CoreMotion

class PedometerManager {
    private let pedometer = CMPedometer()
    
    /// Store the first step reading so we can subtract it out and show only the steps
    /// taken since startUpdates() was called.
    private var initialSteps: Int?
    
    func startUpdates(completion: @escaping (Int, Double?) -> Void) {
        guard CMPedometer.isStepCountingAvailable(),
              CMPedometer.isPaceAvailable()
        else {
            print("Pedometer features not available.")
            return
        }
        
        // Request pedometer data starting "now"
        pedometer.startUpdates(from: Date()) { data, error in
            if let error = error {
                print("Pedometer update error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            // totalSteps is the total steps recorded since `from:` date
            let totalSteps = data.numberOfSteps.intValue
            
            // The first time we get data, record that total as a baseline
            if self.initialSteps == nil {
                self.initialSteps = totalSteps
            }
            
            // Steps since the run started:
            let currentSteps = max(0, totalSteps - (self.initialSteps ?? 0))
            
            // currentPace is in sec/meter; speed in m/s is 1 ÷ currentPace
            var speed: Double?
            if let pace = data.currentPace?.doubleValue, pace > 0 {
                speed = 1.0 / pace
            }
            
            completion(currentSteps, speed)
        }
    }
    
    func stopUpdates() {
        pedometer.stopUpdates()
        initialSteps = nil
    }
}
