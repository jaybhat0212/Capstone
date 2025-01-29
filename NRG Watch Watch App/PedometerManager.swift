//
//  Untitled.swift
//  NRG
//
//  Created by Jay Bhatasana on 2025-01-15.
//

import CoreMotion

class PedometerManager {
    private let pedometer = CMPedometer()
    
    func startUpdates(completion: @escaping (Int, Double?) -> Void) {
        guard CMPedometer.isStepCountingAvailable(), CMPedometer.isPaceAvailable() else {
            print("Pedometer features not available.")
            return
        }
        
        pedometer.startUpdates(from: Date()) { data, _ in
            let steps = data?.numberOfSteps.intValue ?? 0
            let speed = data?.currentPace?.doubleValue
            completion(steps, speed)
        }
    }
}
