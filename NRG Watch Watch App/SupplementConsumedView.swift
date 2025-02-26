import SwiftUI
import WatchKit

struct SupplementConsumedView: View {
    let source: SupplementSource
    
    let onFinalize: () -> Void   // Called after 5s => navigate Home
    let onUndo: (SupplementSource) -> Void   // Called on tapping circle => undo
    
    @State private var progress: CGFloat = 1.0
    @State private var timerCount = 5
    @State private var shouldFinalize = true
    @State private var timer: Timer? = nil
    
    // Fallback to forcefully dismiss if parent's closure doesn't pop this view
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Undo Circle (120×120)
                ZStack {
                    // Background ring (faint)
                    Circle()
                        .stroke(Color.red.opacity(0.3),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                    
                    // Animated progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.red,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.linear(duration: 5), value: progress)
                    
                    // Undo image (arrow.counterclockwise), increased to 60×60
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                }
                // Adjust vertical offset so the undo circle is aligned with the gel notification.
                .offset(y: 5)
                .contentShape(Circle())  // Make entire circle tappable
                .onTapGesture {
                    WKInterfaceDevice.current().play(.failure)
                    timer?.invalidate()
                    shouldFinalize = false
                    onUndo(source)
                }
                
                Text("UNDO \(timerCount)s")
                    .foregroundColor(.red)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.bottom, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startCountdown() {
        progress = 1.0
        timerCount = 5
        shouldFinalize = true
        
        // Timer that decrements the countdown text every second.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerCount > 0 {
                timerCount -= 1
            }
        }
        
        // Animate the circle from full to empty over 5 seconds.
        withAnimation(.linear(duration: 5)) {
            progress = 0.0
        }
        
        // After 5 seconds, finalize if not undone.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if shouldFinalize {
                finalize()
            }
        }
    }
    
    private func finalize() {
        WKInterfaceDevice.current().play(.success)
        onFinalize()
        dismiss()
    }
}

struct SupplementConsumedView_Previews: PreviewProvider {
    static var previews: some View {
        SupplementConsumedView(source: .manual, onFinalize: {}, onUndo: { _ in })
    }
}
