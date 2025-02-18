import SwiftUI
import WatchKit

struct HomeView: View {
    @Binding var elapsedTime: TimeInterval
    let pace: Double?
    @Binding var heartRateVariability: Double?
    @Binding var grade: Double
    let lastGelTime: Date
    
    let onManualGelHold: () -> Void
    
    // For the 3s hold button
    @State private var isHolding = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Text("Time: \(formatTime(elapsedTime))")
                    .foregroundColor(.white)
                
                if let p = pace {
                    Text("Pace: \(String(format: "%.2f", p)) m/s")
                        .foregroundColor(.white)
                } else {
                    Text("Pace: --").foregroundColor(.white)
                }
                
                if let hrv = heartRateVariability {
                    Text("HRV: \(String(format: "%.0f", hrv)) ms")
                        .foregroundColor(.white)
                } else {
                    Text("HRV: --").foregroundColor(.white)
                }
                
                Text("Gradient: \(String(format: "%.2f", grade))")
                    .foregroundColor(.white)
                
                Text("Last Gel: \(formatTimeSince(lastGelTime)) ago")
                    .foregroundColor(.white)
                    .font(.footnote)
                
                // 3-second hold button for manual gel consumption
                Text("Hold 3s to Take Gel")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .gesture(
                        LongPressGesture(minimumDuration: 3.0)
                            .onChanged { _ in
                                isHolding = true
                            }
                            .onEnded { _ in
                                WKInterfaceDevice.current().play(.success)
                                onManualGelHold()
                                isHolding = false
                            }
                    )
            }
            .padding()
        }
    }
    
    // Simple time formatter (MM:SS)
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // How long ago was last gel
    func formatTimeSince(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        let minutes = Int(diff) / 60
        let seconds = Int(diff) % 60
        return "\(minutes)m \(seconds)s"
    }
}
