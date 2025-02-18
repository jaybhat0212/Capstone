import SwiftUI

struct MainTabView: View {
    @Binding var elapsedTime: TimeInterval
    let pace: Double?
    @Binding var heartRateVariability: Double?
    @Binding var grade: Double
    let lastGelTime: Date
    
    // Called if user manually holds for 3s on HomeView's "Taken Gel"
    let onManualGelHold: () -> Void
    
    // Called if user 3s-holds on StopRunView to end run
    let onStopRun: () -> Void
    
    var body: some View {
        TabView {
            // Page 0: HomeView
            HomeView(
                elapsedTime: $elapsedTime,
                pace: pace,
                heartRateVariability: $heartRateVariability,
                grade: $grade,
                lastGelTime: lastGelTime,
                onManualGelHold: onManualGelHold
            )
            .tag(0)
            
            // Page 1: StopRunView
            StopRunView {
                onStopRun()
            }
            .tag(1)
        }
        // This style allows left-right swipe on watch
        .tabViewStyle(PageTabViewStyle())
    }
}
