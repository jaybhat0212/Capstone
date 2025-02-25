import SwiftUI
import WatchKit

struct StopRunView: View {
    let onStopRun: () -> Void
    
    @State private var isPressing = false
    @State private var isAnimating = false
    
    var body: some View {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    // Circle background + Flag icon
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "flag.checkered")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 65, height: 65)
                            .foregroundColor(Color.fromHex("#00FFC5"))
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.2)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                    .onAppear {
                        isAnimating = true
                    }
                    // Attach the 3-second long press to the whole ZStack
                    .gesture(
                        LongPressGesture(minimumDuration: 3.0)
                            .onChanged { _ in
                                // Optionally provide visual feedback here if desired
                            }
                            .onEnded { _ in
                                WKInterfaceDevice.current().play(.success)
                                onStopRun()
                            }
                    )
                    
                    Text("FINISH RUN")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
        }
    }
