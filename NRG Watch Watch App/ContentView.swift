//
//  ContentView.swift
//  NRG
//
//  High-level app flow:
//
//  1. If metrics are not ready (first launch), show FirstLaunchView.
//     -> Then leads to StartScreen.
//
//  2. StartScreen -> press "Start" -> startTracking() -> show MainTabView.
//
//  3. MainTabView has two pages:
//     - Page 0: HomeView (time, pace, HRV, gradient, last gel, manual 3s hold => SupplementConsumedView)
//     - Page 1: StopRunView (3s hold to end run => back to StartScreen)
//
//  4. If any of the 3 rules triggers a gel notification, navigate to SupplementView (3s hold) -> SupplementConsumedView.
//
//  5. SupplementConsumedView:
//     - Displays "Gel intake recorded" with 5s auto-return to HomeView (finalizing the consumption).
//     - Has "Undo" => return to either HomeView (manual) or SupplementView (auto).
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
    // MARK: - First Launch
    @State private var isShowingFirstLaunch: Bool = true
    @State private var isMetricsReady: Bool = false
    @State private var restingVO2: Double? = nil
    @State private var bodyMass: Double? = nil
    
    // MARK: - Tracking
    @State private var elapsedTime: TimeInterval = 0
    @State private var runningSpeed: Double? = nil
    @State private var heartRateVariability: Double? = nil
    @State private var totalDistance: Double = 0
    @State private var grade: Double = 0
    @State private var totalCaloriesBurned: Double = 0
    
    @State private var startTime: Date? = nil
    @State private var timer: Timer? = nil
    @State private var lastSupplementIntakeTime: Date = Date()
    
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
            // A) If first launch needed
            if isShowingFirstLaunch {
                FirstLaunchView(
                    isMetricsReady: $isMetricsReady,
                    restingVO2: $restingVO2,
                    bodyMass: $bodyMass
                )
                .onChange(of: isMetricsReady) { newValue in
                    if newValue {
                        // Done => show StartScreen
                        isShowingFirstLaunch = false
                        showStartScreen = true
                    }
                }
            }
            // B) Show StartScreen
            else if showStartScreen {
                StartScreen {
                    startTracking()
                    showStartScreen = false
                    showTracking = true
                }
            }
            // C) Show the main tab (HomeView + StopRunView)
            else if showTracking {
                MainTabView(
                    elapsedTime: $elapsedTime,
                    pace: computedPace,
                    heartRateVariability: $heartRateVariability,
                    grade: $grade,
                    lastGelTime: lastSupplementIntakeTime,
                    
                    // 1) Called if user holds "Taken Gel" for 3s (manual)
                    onManualGelHold: {
                        supplementSource = .manual
                        showSupplementConsumed = true
                    },
                    
                    // 2) Called from StopRunView 3s hold => End run => Back to StartScreen
                    onStopRun: {
                        stopTracking() // stops time, metrics
                        showTracking = false
                        showStartScreen = true
                    }
                )
                // Automatic rules => SupplementView
                .navigationDestination(isPresented: $showSupplementView) {
                    SupplementView {
                        supplementSource = .auto
                        showSupplementConsumed = true
                    }
                    .navigationBarBackButtonHidden(true)
                }
                // After 3s hold => or from auto => show "Gel intake recorded" screen
                .navigationDestination(isPresented: $showSupplementConsumed) {
                    SupplementConsumedView(
                        source: supplementSource,
                        onFinalize: finalizeSupplementIntake,
                        onUndo: undoSupplementIntake
                    )
                    .navigationBarBackButtonHidden(true) // Remove back button
                }
            }
        }
    }
}


// MARK: - Private Methods
extension ContentView {
    
    /// Computed pace (m/s) => distance/time
    private var computedPace: Double? {
        guard elapsedTime > 0 else { return nil }
        return totalDistance / elapsedTime
    }
    
    /// Start the run
    func startTracking() {
        // Do NOT reset lastSupplementIntakeTime => we keep it from before
        startTime = Date()
        elapsedTime = 0
        totalDistance = 0
        totalCaloriesBurned = 0
        
        // 1-second timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let startTime = startTime else { return }
            elapsedTime = Date().timeIntervalSince(startTime)
            checkSupplementConditions()
        }
        
        // Start pedometer & HRV updates
        motionManager.startUpdates { distance, speed, floorsAscDesc, hrv in
            DispatchQueue.main.async {
                self.totalDistance = distance ?? 0
                self.runningSpeed = speed ?? 0
                self.grade = convertFloorsToGrade(floorsAscDesc)
                self.heartRateVariability = hrv
                accumulateCalories()
            }
        }
    }
    
    /// Stop the run
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        motionManager.stopUpdates()
        elapsedTime = 0
        totalDistance = 0
        totalCaloriesBurned = 0
        runningSpeed = nil
        heartRateVariability = nil
        grade = 0
        
        // Return to start screen
        showTracking = false
        showStartScreen = true
    }
    
    /// Check 3 supplement rules each second
    func checkSupplementConditions() {
        let now = Date()
        
        // 1) More than 1 hour
        if now >= lastSupplementIntakeTime.addingTimeInterval(3600) {
            triggerSupplementAlert()
            return
        }
        
        // 2) HRV < 65
        if let hrv = heartRateVariability, hrv < 65 {
            triggerSupplementAlert()
            return
        }
        
        // 3) Over 120kcal & 30+ min since last gel
        if totalCaloriesBurned >= 120,
           now >= lastSupplementIntakeTime.addingTimeInterval(1800) {
            triggerSupplementAlert()
            return
        }
    }
    
    /// Navigate to SupplementView (auto-trigger flow)
    func triggerSupplementAlert() {
        // Stop the timer so we don't repeatedly trigger
        timer?.invalidate()
        timer = nil
        
        WKInterfaceDevice.current().play(.success)
        showSupplementView = true
    }
    
    /// Called from "SupplementConsumedView" -> "Finalize"
    /// Sets the new gel time if accepted, then re-starts the timer if needed
    func finalizeSupplementIntake() {
        // Update last gel time => do NOT reset timer
        lastSupplementIntakeTime = Date()
        totalCaloriesBurned = 0
        
        // If we want to keep run going, re-start the timer
        if startTime != nil, timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                guard let startTime = startTime else { return }
                elapsedTime = Date().timeIntervalSince(startTime)
                checkSupplementConditions()
            }
        }
    }
    
    /// Called from "SupplementConsumedView" -> "Undo"
    /// Return to HomeView or SupplementView based on source
    func undoSupplementIntake(_ source: SupplementSource) {
        // If we were in auto flow, go back to SupplementView
        // If we were in manual flow, go back to HomeView
        switch source {
        case .auto:
            showSupplementConsumed = false
            showSupplementView = true
        case .manual:
            showSupplementConsumed = false
        case .none:
            // Shouldn't happen, do nothing
            break
        }
    }
    
    /// Convert floors to gradient
    func convertFloorsToGrade(_ floorsAscDesc: Double?) -> Double {
        guard let floors = floorsAscDesc else { return 0 }
        let verticalMeters = floors * 3.0
        let horizontal = max(totalDistance, 1)
        return verticalMeters / horizontal
    }
    
    /// Calories via the standard formula
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
