import SwiftUI
import WatchKit

struct SupplementConsumedView: View {
    let source: SupplementSource
    
    let onFinalize: () -> Void
    let onUndo: (SupplementSource) -> Void
    
    @State private var progress: CGFloat = 1.0
    @State private var timerCount = 5
    @State private var shouldFinalize = true
    @State private var timer: Timer? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Undo Circle (120×120)
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(0.3),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.red,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.linear(duration: 5), value: progress)
                    
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                }
                .offset(y: 5)
                .contentShape(Circle())
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
        .onAppear { startCountdown() }
        .onDisappear { timer?.invalidate() }
    }
    
    private func startCountdown() {
        progress = 1.0
        timerCount = 5
        shouldFinalize = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerCount > 0 {
                timerCount -= 1
            }
        }
        
        withAnimation(.linear(duration: 5)) {
            progress = 0.0
        }
        
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
