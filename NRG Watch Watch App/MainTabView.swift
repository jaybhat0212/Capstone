//
//  WatchMainTabView.swift
//  NRG
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var healthManager: HealthManager

    @Binding var elapsedTime: TimeInterval
    let pace: Double?
    @Binding var heartRateVariability: Double?
    @Binding var grade: Double
    @Binding var vo2Max: Double?

    let lastGelTime: TimeInterval
    let totalDistance: Double
    let runningSpeed: Double?
    let totalCaloriesBurned: Double
    @Binding var heartRate: Double?

    let onManualGelHold: () -> Void
    let onStopRun: () -> Void

    var body: some View {
        TabView {
            // Page 0: HomeView
            HomeView(
                elapsedTime: $elapsedTime,
                pace: pace,
                heartRate: $heartRate,
                heartRateVariability: $heartRateVariability,
                grade: $grade,
                lastGelTime: lastGelTime,
                onManualGelHold: onManualGelHold
            )
            .tag(0)

            // Page 1: MetricsView
            MetricsView(
                elapsedTime: $elapsedTime,
                pace: pace,
                heartRateVariability: $heartRateVariability,
                heartRate: $heartRate,
                vo2Max: $vo2Max,
                grade: $grade,
                lastGelTime: lastGelTime,
                totalDistance: totalDistance,
                runningSpeed: runningSpeed,
                totalCaloriesBurned: totalCaloriesBurned,
                gelServing: $healthManager.phoneGelCalories,
                bodyMass: $healthManager.bodyMass,  // ✅ Pass Body Mass Binding
                healthManager: healthManager
            )
            .tag(1)

            // Page 2: StopRunView
            StopRunView {
                onStopRun()
            }
            .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(
            healthManager: HealthManager(),
            elapsedTime: .constant(125),
            pace: 10.0,
            heartRateVariability: .constant(75),
            grade: .constant(0.05),
            vo2Max: .constant(35),
            lastGelTime: 0,
            totalDistance: 3500,
            runningSpeed: 3.5,
            totalCaloriesBurned: 150,
            heartRate: .constant(72),
            onManualGelHold: {},
            onStopRun: {}
        )
    }
}
