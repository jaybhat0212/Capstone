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
    @State private var vo2: Double? = nil
    @State private var totalDistance: Double = 0
    @State private var grade: Double = 0
    @State private var totalCaloriesBurned: Double = 0
    
    @State private var startTime: Date? = nil
    @State private var timer: Timer? = nil
    @State private var lastSupplementIntakeTime: TimeInterval = 0
    @State private var gelIntakeTimes: [TimeInterval] = []
    
    // Managers
    private let healthManager = HealthManager()
    private let motionManager = MotionManager()
    
    // MARK: - Navigation Flow
    @State private var showStartScreen: Bool = false
    @State private var showTracking: Bool = false
    @State private var showSupplementView: Bool = false
    @State private var showSupplementConsumed: Bool = false
    @State private var supplementSource: SupplementSource = .none
    
    var body: some View {
        NavigationStack {
            if isShowingFirstLaunch {
                FirstLaunchView(isMetricsReady: $isMetricsReady,
                                restingVO2: $restingVO2,
                                bodyMass: $bodyMass)
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
                    heartRate: $heartRate,
                    heartRateVariability: $heartRateVariability,
                    vo2: vo2,
                    grade: $grade,
                    lastGelTime: lastSupplementIntakeTime,
                    totalDistance: totalDistance,
                    runningSpeed: runningSpeed,
                    totalCaloriesBurned: totalCaloriesBurned,
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
        .background(
            LinearGradient(gradient: Gradient(colors: [.black, .gray]),
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            healthManager.fetchAllHealthMetrics { vo2, bodyMass, hrv, heartRate in
                DispatchQueue.main.async {
                    self.vo2 = vo2
                    self.bodyMass = bodyMass
                    self.heartRateVariability = hrv
                    self.heartRate = heartRate
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var computedPace: Double? {
        guard elapsedTime > 0 else { return nil }
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
        
        motionManager.startUpdates { distance, speed, floorsAscDesc, hrv, hr in
            DispatchQueue.main.async {
                self.totalDistance = distance ?? self.totalDistance
                self.runningSpeed = speed ?? 0
                self.grade = convertFloorsToGrade(floorsAscDesc)

                if let newHRV = hrv {
                    self.heartRateVariability = newHRV
                }
                if let newHR = hr {
                    self.heartRate = newHR
                }

                accumulateCalories()
            }
        }
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        motionManager.stopUpdates()
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
        WKInterfaceDevice.current().play(.success)  // 🔔 Haptic feedback to notify user
        showSupplementView = true
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
        let vo2Calc = (0.2 * speedMPerMin) + (0.9 * speedMPerMin * grade) + vo2Rest
        let litersO2PerMin = vo2Calc * (mass / 1000.0)
        let kcalPerMin = litersO2PerMin * 4.9
        let kcalPerSecond = kcalPerMin / 60.0
        totalCaloriesBurned += kcalPerSecond
    }
}
