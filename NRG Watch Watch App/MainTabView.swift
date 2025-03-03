import SwiftUI

struct MainTabView: View {
    @Binding var elapsedTime: TimeInterval
    let pace: Double?
    @Binding var heartRate: Double?             // New binding for heart rate
    @Binding var heartRateVariability: Double?
    let vo2: Double?                              // New parameter for VO₂
    @Binding var grade: Double
    let lastGelTime: TimeInterval
    
    // Additional metrics for MetricsView
    let totalDistance: Double
    let runningSpeed: Double?
    let totalCaloriesBurned: Double
    
    // Called if user manually holds for 3s on HomeView's "Taken Gel"
    let onManualGelHold: () -> Void
    
    // Called if user 3s-holds on StopRunView to end run
    let onStopRun: () -> Void
    
    var body: some View {
        TabView {
            // Page 0: HomeView – shows heart rate.
            HomeView(
                elapsedTime: $elapsedTime,
                pace: pace,
                heartRate: $heartRate,            // Pass heart rate binding
                grade: $grade,
                lastGelTime: lastGelTime,
                onManualGelHold: onManualGelHold
            )
            .tag(0)
            
            // Page 1: MetricsView – shows heart rate, HRV, and VO₂.
            MetricsView(
                elapsedTime: $elapsedTime,
                pace: pace,
                heartRate: $heartRate,            // New parameter for heart rate
                heartRateVariability: $heartRateVariability,
                vo2: vo2,                         // Pass VO₂ value
                grade: $grade,
                lastGelTime: lastGelTime,
                totalDistance: totalDistance,
                runningSpeed: runningSpeed,
                totalCaloriesBurned: totalCaloriesBurned
            )
            .tag(1)
            
            // Page 2: StopRunView
            StopRunView {
                onStopRun()
            }
            .tag(2)
        }
        // This style allows left-right swipe on the watch.
        .tabViewStyle(PageTabViewStyle())
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(
            elapsedTime: .constant(125),
            pace: 10.0,
            heartRate: .constant(72),
            heartRateVariability: .constant(75),
            vo2: 35.0,
            grade: .constant(0.05),
            lastGelTime: 0,
            totalDistance: 3500,
            runningSpeed: 3.5,
            totalCaloriesBurned: 150,
            onManualGelHold: {},
            onStopRun: {}
        )
    }
}
