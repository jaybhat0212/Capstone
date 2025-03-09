import SwiftUI
import WatchKit

struct HomeView: View {
    @Binding var elapsedTime: TimeInterval
    let pace: Double?
    
    // NEW: We accept heartRate instead of using heartRateVariability
    @Binding var heartRate: Double?
    
    // We still allow HRV if you want to display or handle it separately,
    // but the user requested to show *heart rate* on the main page.
    @Binding var heartRateVariability: Double?
    
    @Binding var grade: Double
    let lastGelTime: TimeInterval  // elapsed time when gel was taken
    
    let onManualGelHold: () -> Void
    
    // State for the hold gesture with ring animation
    @State private var isPressing = false
    @State private var holdProgress: CGFloat = 0.0
    @State private var holdTimer: Timer? = nil
    
    // Pulsing animation for the center icon
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 4) {
                // 1) Hold gesture area with ring and pulsing image
                ZStack {
                    Circle()
                        .stroke(Color.fromHex("#00FFC5").opacity(0.2), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0.0, to: holdProgress)
                        .stroke(Color.fromHex("#00FFC5"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                        .animation(.linear, value: holdProgress)
                    
                    Image("NRGRun")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear {
                            isPulsing = true
                        }
                }
                .offset(y: -5)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressing {
                                isPressing = true
                                startHoldTimer()
                            }
                        }
                        .onEnded { _ in
                            endHoldGesture()
                        }
                )
                
                // 2) Time counter
                Text(formatTime(elapsedTime))
                    .font(.title3)
                    .foregroundColor(.white)
                
                Divider()
                    .frame(width: 160)
                    .background(Color.gray)
                    .padding(.top, 8)
                
                // "Avg Pace" and "Last Gel" info
                HStack(alignment: .top) {
                    VStack(spacing: 2) {
                        Text("Avg Pace")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        if let p = pace {
                            Text("\(String(format: "%.2f", p)) km/h")
                                .foregroundColor(.white)
                        } else {
                            Text("-- km/h")
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("Last Gel")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text(lastGelTime > 0 ? formatGelTime(lastGelTime) : "00:00:00")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                
                Divider()
                    .frame(width: 160)
                    .background(Color.gray)
                
                Spacer()
                
                // Bottom row: distance and heart rate
                HStack {
                    Text("\(distanceString()) km")
                        .foregroundColor(.white)
                        .padding(.leading, 12)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        
                        // Display heartRate on the main page
                        if let hr = heartRate {
                            Text("\(Int(hr)) BPM")
                                .foregroundColor(.white)
                        } else {
                            Text("--")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 12)
                }
                .padding(.bottom, 6)
            }
        }
        .onAppear {
            endHoldGesture()
        }
    }
    
    // MARK: - Hold Gesture Helpers
    
    func startHoldTimer() {
        holdProgress = 0.0
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            holdProgress += 0.01 / 3.0
            if holdProgress >= 1.0 {
                holdProgress = 1.0
                WKInterfaceDevice.current().play(.success)
                onManualGelHold()
                endHoldGesture()
            }
        }
    }
    
    func endHoldGesture() {
        holdTimer?.invalidate()
        holdTimer = nil
        isPressing = false
        holdProgress = 0.0
    }
    
    // MARK: - Helper Methods
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func distanceString() -> String {
        guard let p = pace else { return "--" }
        let distanceInMeters = p * elapsedTime
        let distanceInKm = distanceInMeters / 1000.0
        return String(format: "%.2f", distanceInKm)
    }
    
    func formatGelTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
