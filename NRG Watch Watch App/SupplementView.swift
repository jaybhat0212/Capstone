import SwiftUI
import WatchKit

struct SupplementView: View {
    let onConfirmHold: () -> Void
    
    // State for the hold gesture with ring animation
    @State private var isPressing = false
    @State private var holdProgress: CGFloat = 0.0
    @State private var holdTimer: Timer? = nil
    
    // New state for pulsing the image.
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Enlarged notification circle (120×120)
                ZStack {
                    // Background ring (faint)
                    Circle()
                        .stroke(Color.fromHex("#00FFC5").opacity(0.2), lineWidth: 10)
                        .frame(width: 120, height: 120)
                    
                    // Animated progress ring
                    Circle()
                        .trim(from: 0.0, to: holdProgress)
                        .stroke(Color.fromHex("#00FFC5"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.linear, value: holdProgress)
                    
                    // NRGRun image (increased to 60×60) with pulsing animation.
                    Image("NRGRun")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear {
                            isPulsing = true
                        }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressing {
                                isPressing = true
                                startHoldTimer()
                            }
                        }
                        .onEnded { _ in
                            endHoldTimer()
                        }
                )
                
                // Simple notification text.
                Text("Time to take a gel pack")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .medium))
            }
        }
    }
    
    // MARK: - Hold Gesture Helpers
    
    func startHoldTimer() {
        holdProgress = 0.0
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            holdProgress += 0.01 / 3.0  // Fill over 3 seconds
            if holdProgress >= 1.0 {
                holdProgress = 1.0
                WKInterfaceDevice.current().play(.success)
                onConfirmHold()
                endHoldTimer()
            }
        }
    }
    
    func endHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
        isPressing = false
        holdProgress = 0.0
    }
}

struct SupplementView_Previews: PreviewProvider {
    static var previews: some View {
        SupplementView {
            // Preview action.
        }
    }
}
