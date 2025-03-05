import SwiftUI
import WatchKit

struct StopRunView: View {
    let onStopRun: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Button(action: {
                    WKInterfaceDevice.current().play(.success)
                    onStopRun()
                }) {
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
                }
                .buttonStyle(.plain)
                .onAppear {
                    isAnimating = true
                }
                
                Text("FINISH RUN")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }
}

struct StopRunView_Previews: PreviewProvider {
    static var previews: some View {
        StopRunView {
            // Preview action
        }
    }
}
