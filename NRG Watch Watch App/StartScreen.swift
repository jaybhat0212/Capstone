import SwiftUI
import WatchKit

struct StartScreen: View {
    let onStart: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Button(action: {
                    WKInterfaceDevice.current().play(.success)
                    onStart()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 65, height: 65)
                            .foregroundColor(Color.fromHex("#00FFC5"))
                            .scaleEffect(isAnimating ? 1.06 : 0.9)
                            .animation(
                                .easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                }
                .buttonStyle(.plain)
                .onAppear { isAnimating = true }
                
                Text("START")
                    .font(.system(size: 27, weight: .bold))
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }
}
