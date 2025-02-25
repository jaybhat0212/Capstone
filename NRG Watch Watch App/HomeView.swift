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
            
            VStack(spacing: 4) {
                
                // 1) Large icon at the top, moved up a bit
                Image("NRGRun")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)   // Larger icon
                    .offset(y: -5)                // Moves the icon up slightly
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
                
                // 2) Bigger time counter
                Text(formatTime(elapsedTime))
                    .font(.title3)               // Bigger font than title3
                    .foregroundColor(.white)
                
                // First divider
                Divider()
                    .frame(width: 160)
                    .background(Color.gray)
                    .padding(.top, 8)
                
                // "Avg Pace" label + pace below
                HStack(alignment: .top) {
                    // LEFT: Avg Pace
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
                    
                    // RIGHT: Time Since Last Gel
                    VStack(spacing: 2) {
                        Text("Last Gel")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        // Show how long since lastGelTime
                        Text(formatTimeSince(lastGelTime))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                
                // Second divider
                Divider()
                    .frame(width: 160)
                    .background(Color.gray)
                
                Spacer()
                
                // Bottom row: Distance on the left + Heart icon & rate on the right
                HStack {
                    Text("\(distanceString()) km")
                        .foregroundColor(.white)
                        .padding(.leading, 12)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        
                        if let hrv = heartRateVariability {
                            Text("\(Int(hrv))") // e.g., "75 BPM"
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
    }
    
    // Simple time formatter (MM:SS)
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
    
    // How long ago was last gel
    func formatTimeSince(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        let minutes = Int(diff) / 60
        let seconds = Int(diff) % 60
        return "\(minutes)m \(seconds)s"
    }
}
