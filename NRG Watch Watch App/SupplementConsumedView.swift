import SwiftUI
import WatchKit

struct SupplementConsumedView: View {
    let source: SupplementSource
    
    let onFinalize: () -> Void  // Called after 5s
    let onUndo: (SupplementSource) -> Void  // Called if user presses "Undo"
    
    @State private var timerCount = 5
    @State private var shouldFinalize = true // Ensures auto-return works
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Gel intake recorded!")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.bottom, 5)
                
                Text("Undo? \(timerCount)s")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                    .padding(.bottom, 10)
                
                Button("Undo") {
                    WKInterfaceDevice.current().play(.failure)
                    timer?.invalidate()  // Stop auto-finalizing
                    shouldFinalize = false
                    onUndo(source)  // Go back
                }
                .padding(10)
                .background(Color.gray)
                .cornerRadius(8)
                .foregroundColor(.white)
            }
        }
        .navigationBarBackButtonHidden(true)  // Ensure there's no back button
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()  // Cleanup
        }
    }
    
    private func startCountdown() {
        timerCount = 5
        shouldFinalize = true // Reset condition
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerCount > 0 {
                timerCount -= 1
            } else {
                timer?.invalidate()
                if shouldFinalize {
                    finalize()
                }
            }
        }
    }
    
    private func finalize() {
        WKInterfaceDevice.current().play(.success)
        onFinalize()  // Returns to HomeView automatically
    }
}
