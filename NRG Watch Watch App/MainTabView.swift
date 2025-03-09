import SwiftUI

struct MainTabView: View {
    @Binding var elapsedTime: TimeInterval
    let pace: Double?
    @Binding var heartRateVariability: Double?
    @Binding var grade: Double
    
    let vo2Max: Double?
    
    let lastGelTime: TimeInterval
    
    let totalDistance: Double
    let runningSpeed: Double?
    let totalCaloriesBurned: Double
    
    // NEW: We pass in heartRate as well
    @Binding var heartRate: Double?
    
    // Called if user manually holds for 3s on HomeView's “Taken Gel”
    let onManualGelHold: () -> Void
    
    // Called if user holds the StopRunView
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
                grade: $grade,
                heartRate: $heartRate,
                vo2Max: vo2Max,
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
            heartRateVariability: .constant(75),
            grade: .constant(0.05),
            vo2Max: 35.0,
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
