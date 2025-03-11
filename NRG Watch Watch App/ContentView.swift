import SwiftUI
import HealthKit
import WatchKit

enum SupplementSource {
    case manual
    case auto
    case none
}

struct ContentView: View {
    // MARK: - First Launch
    @State private var isShowingFirstLaunch: Bool = true
    @State private var isMetricsReady: Bool = false
    @State private var restingVO2: Double? = nil
    @State private var bodyMass: Double? = nil
    
    // MARK: - Tracking
    @State private var elapsedTime: TimeInterval = 0
    @State private var runningSpeed: Double? = nil
    @State private var heartRateVariability: Double? = nil
    @State private var heartRate: Double? = nil
    @State private var totalDistance: Double = 0
    @State private var grade: Double = 0
    @State private var totalCaloriesBurned: Double = 0
    
    // --------------------------------------------
    // IMPORTANT: We add a @State for vo2Max
    // --------------------------------------------
    @State private var vo2Max: Double? = nil
    
    @State private var startTime: Date? = nil
    @State private var timer: Timer? = nil
    
    // Gel consumption times
    @State private var lastSupplementIntakeTime: TimeInterval = 0
    @State private var gelIntakeTimes: [TimeInterval] = []
    
    // Managers
    private let healthManager = HealthManager()
    private let motionManager = MotionManager()
    
    // MARK: - Navigation Flow
    @State private var showStartScreen: Bool = false
    @State private var showTracking: Bool = false
    
    // Supplement Flow
    @State private var showSupplementView: Bool = false
    @State private var showSupplementConsumed: Bool = false
    @State private var supplementSource: SupplementSource = .none
    
    var body: some View {
        NavigationStack {
            if isShowingFirstLaunch {
                FirstLaunchView(
                    isMetricsReady: $isMetricsReady,
                    restingVO2: $restingVO2,
                    bodyMass: $bodyMass
                )
                .onChange(of: isMetricsReady) { newValue in
                    if newValue {
                        isShowingFirstLaunch = false
                        showStartScreen = true
                    }
                }
            } else if showStartScreen {
                StartScreen {
                    startTracking()
                    showStartScreen = false
                    showTracking = true
                }
            } else if showTracking {
                MainTabView(
                    elapsedTime: $elapsedTime,
                    pace: computedPace,
                    heartRateVariability: $heartRateVariability,
                    grade: $grade,
                    vo2Max: $vo2Max,
                    lastGelTime: lastSupplementIntakeTime,
                    totalDistance: totalDistance,
                    runningSpeed: runningSpeed,
                    totalCaloriesBurned: totalCaloriesBurned,
                    heartRate: $heartRate,
                    onManualGelHold: {
                        supplementSource = .manual
                        showSupplementConsumed = true
                    },
                    onStopRun: {
                        stopTracking()
                        showTracking = false
                        showStartScreen = true
                    }
                )
                .navigationDestination(isPresented: $showSupplementView) {
                    SupplementView {
                        supplementSource = .auto
                        showSupplementConsumed = true
                    }
                    .navigationBarBackButtonHidden(true)
                }
                .navigationDestination(isPresented: $showSupplementConsumed) {
                    SupplementConsumedView(
                        source: supplementSource,
                        onFinalize: finalizeSupplementIntake,
                        onUndo: undoSupplementIntake
                    )
                    .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var computedPace: Double? {
        guard elapsedTime > 0 else { return nil }
        // totalDistance is in meters -> pace in m/s => converting to km/h
        return totalDistance / elapsedTime
    }
    
    // MARK: - Tracking Methods
    
    func startTracking() {
        startTime = Date()
        elapsedTime = 0
        totalDistance = 0
        totalCaloriesBurned = 0
        lastSupplementIntakeTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let startTime = startTime else { return }
            elapsedTime = Date().timeIntervalSince(startTime)
            checkSupplementConditions()
        }
        
        // ---------------------------------------------------------------------
        // START MOTION UPDATES, retrieving distance, speed, floorsAscDesc, HRV, HR, VO2
        // ---------------------------------------------------------------------
        motionManager.startUpdates { dist, speed, floorsAscDesc, hrv, hr, vo2 in
            DispatchQueue.main.async {
                self.totalDistance = dist ?? 0
                self.runningSpeed = speed ?? 0
                self.grade = convertFloorsToGrade(floorsAscDesc)
                
                self.heartRateVariability = hrv
                self.heartRate = hr
                
                // This updates self.vo2Max in real time
                self.vo2Max = vo2
                
                self.accumulateCalories()
            }
        }
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        motionManager.stopUpdates()
        elapsedTime = 0
        totalDistance = 0
        totalCaloriesBurned = 0
        runningSpeed = nil
        heartRateVariability = nil
        heartRate = nil
        vo2Max = nil
        grade = 0
    }
    
    func checkSupplementConditions() {
        let currentElapsed = elapsedTime
        if currentElapsed >= lastSupplementIntakeTime + 2700 {
            triggerSupplementAlert()
            return
        }
        if let hrv = heartRateVariability, hrv > 65 {
            triggerSupplementAlert()
            return
        }
        if totalCaloriesBurned >= 120 && currentElapsed >= lastSupplementIntakeTime + 1800 {
            triggerSupplementAlert()
            return
        }
    }
    
    func triggerSupplementAlert() {
        timer?.invalidate()
        timer = nil
        WKInterfaceDevice.current().play(.success)
        showSupplementView = true
    }
    
    func finalizeSupplementIntake() {
        if let startTime = startTime {
            let currentElapsed = Date().timeIntervalSince(startTime)
            elapsedTime = currentElapsed
            lastSupplementIntakeTime = currentElapsed
            gelIntakeTimes.append(currentElapsed)
        }
        totalCaloriesBurned = 0
        
        if startTime != nil, timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                guard let startTime = startTime else { return }
                elapsedTime = Date().timeIntervalSince(startTime)
                checkSupplementConditions()
            }
        }
    }
    
    func undoSupplementIntake(_ source: SupplementSource) {
        switch source {
        case .auto:
            showSupplementConsumed = false
            showSupplementView = true
        case .manual:
            showSupplementConsumed = false
        case .none:
            break
        }
    }
    
    func convertFloorsToGrade(_ floorsAscDesc: Double?) -> Double {
        guard let floors = floorsAscDesc else { return 0 }
        let verticalMeters = floors * 3.0
        let horizontal = max(totalDistance, 1)
        return verticalMeters / horizontal
    }
    
    func accumulateCalories() {
        guard let vo2Rest = restingVO2, let mass = bodyMass else { return }
        let speedMPerMin = (runningSpeed ?? 0) * 60
        let vo2 = (0.2 * speedMPerMin) + (0.9 * speedMPerMin * grade) + vo2Rest
        let litersO2PerMin = vo2 * (mass / 1000.0)
        let kcalPerMin = litersO2PerMin * 4.9
        let kcalPerSecond = kcalPerMin / 60.0
        totalCaloriesBurned += kcalPerSecond
    }
}
