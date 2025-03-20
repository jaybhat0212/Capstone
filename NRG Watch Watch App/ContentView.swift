//
//  WatchContentView.swift
//  NRG
//

import SwiftUI
import HealthKit
import WatchKit

enum SupplementSource {
    case manual
    case auto
    case none
}

struct ContentView: View {
    // MARK: - Tracking
    @State private var elapsedTime: TimeInterval = 0
    @State private var runningSpeed: Double? = nil
    @State private var heartRateVariability: Double? = nil
    @State private var heartRate: Double? = nil
    @State private var totalDistance: Double = 0
    @State private var grade: Double = 0
    @State private var totalCaloriesBurned: Double = 0

    // VO2 max
    @State private var vo2Max: Double? = nil

    // If you need them for calorie calculation:
    @State private var restingVO2: Double? = nil
    @State private var bodyMass: Double? = nil

    // Gel consumption times
    @State private var lastSupplementIntakeTime: TimeInterval = 0
    @State private var gelIntakeTimes: [TimeInterval] = []

    // Timer
    @State private var startTime: Date?
    @State private var timer: Timer?

    // Managers
    @ObservedObject var healthManager = HealthManager()
    private let motionManager = MotionManager()

    // Flow
    @State private var showStartScreen = true
    @State private var showTracking = false

    // Supplement Flow
    @State private var showSupplementView = false
    @State private var showSupplementConsumed = false
    @State private var supplementSource: SupplementSource = .none

    var body: some View {
        NavigationStack {
            if showStartScreen {
                StartScreen {
                    startTracking()
                    showStartScreen = false
                    showTracking = true
                }
            } else if showTracking {
                MainTabView(
                    healthManager: healthManager,  // pass manager down
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
        .onAppear {
            healthManager.requestAuthorization { success in
            }
            healthManager.requestDataFromPhone()
        }
    }

    // MARK: - Computed
    private var computedPace: Double? {
        guard elapsedTime > 0 else { return nil }
        // totalDistance is in meters -> pace in m/s => km/h
        return totalDistance / elapsedTime
    }

    // MARK: - Tracking
    func startTracking() {
        startTime = Date()
        elapsedTime = 0
        totalDistance = 0
        totalCaloriesBurned = 0
        lastSupplementIntakeTime = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let startTime = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
            self.checkSupplementConditions()
        }

        motionManager.startUpdates { dist, speed, floorsAscDesc, hrv, hr, vo2 in
            DispatchQueue.main.async {
                self.totalDistance = dist ?? 0
                self.runningSpeed = speed ?? 0
                self.grade = self.convertFloorsToGrade(floorsAscDesc)
                self.heartRateVariability = hrv
                self.heartRate = hr

                // We'll update vo2Max if a *new* sample arrives anchored
                if let newVO2 = vo2 {
                    self.vo2Max = newVO2
                }

                // If you want to do calorie calc with local watch data:
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
        
        // If 45 min since last gel, etc.
        if currentElapsed >= lastSupplementIntakeTime + 3000 {
            triggerSupplementAlert()
            return
        }
        if let hrv = heartRateVariability, hrv > 65 && currentElapsed >= lastSupplementIntakeTime + 1800 {
            triggerSupplementAlert()
            return
        }

        // Using phoneGelCalories from watch's HealthManager
        let gelCals = Double(healthManager.phoneGelCalories)
        if totalCaloriesBurned >= gelCals && currentElapsed >= lastSupplementIntakeTime + 1800 {
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
                guard let st = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(st)
                self.checkSupplementConditions()
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
        guard let vo2Rest = restingVO2 else { return }
        let speedMPerMin = (runningSpeed ?? 0) * 60
        let weight = healthManager.bodyMass  // Use synced weight
        let vo2 = (0.2 * speedMPerMin) + (0.9 * speedMPerMin * grade) + vo2Rest
        let litersO2PerMin = vo2 * (weight / 1000.0)
        let kcalPerMin = litersO2PerMin * 4.9
        let kcalPerSecond = kcalPerMin / 60.0
        totalCaloriesBurned += kcalPerSecond
    }

}
