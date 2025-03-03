import SwiftUI
import WatchKit

struct HomeView: View {
    @Binding var elapsedTime: TimeInterval
    let pace: Double?
    @Binding var heartRate: Double?          // Updated binding for heart rate
    @Binding var grade: Double
    let lastGelTime: TimeInterval  // elapsed time when gel was taken
    
    let onManualGelHold: () -> Void
    
    // State for the hold gesture with ring animation
    @State private var isPressing = false
    @State private var holdProgress: CGFloat = 0.0
    @State private var holdTimer: Timer? = nil
    
    // New state for pulsing the NRGRun image.
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 4) {
                // 1) Hold gesture area with ring and pulsing image
                ZStack {
                    // Background ring (faint)
                    Circle()
                        .stroke(Color.fromHex("#00FFC5").opacity(0.2), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    // Animated progress ring that fills up over 3 seconds
                    Circle()
                        .trim(from: 0.0, to: holdProgress)
                        .stroke(Color.fromHex("#00FFC5"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                        .animation(.linear, value: holdProgress)
                    
                    // The NRGRun image that pulses
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
                // Use a DragGesture (with zero minimum distance) to track press start and end
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
                
                // "Avg Pace" and "Last Gel" information.
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
                
                // Bottom row: distance and heart rate.
                HStack {
                    Text("\(distanceString()) km")
                        .foregroundColor(.white)
                        .padding(.leading, 12)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        
                        if let hr = heartRate {
                            Text("\(Int(hr)) bpm")
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
            endHoldGesture() // Reset the progress ring when HomeView appears.
        }
    }
    
    // MARK: - Hold Gesture Helpers
    
    /// Starts a timer that increments `holdProgress` from 0 to 1 over 3 seconds.
    func startHoldTimer() {
        holdProgress = 0.0
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            holdProgress += 0.01 / 3.0  // Linear increment over 3 seconds
            if holdProgress >= 1.0 {
                holdProgress = 1.0
                WKInterfaceDevice.current().play(.success)
                onManualGelHold()
                endHoldGesture()
            }
        }
    }
    
    /// Ends the hold gesture and resets progress.
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
    
    // Formats a TimeInterval (seconds elapsed) as HH:mm:ss.
    func formatGelTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
