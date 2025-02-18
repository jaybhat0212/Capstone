import SwiftUI
import WatchKit

struct SupplementView: View {
    let onConfirmHold: () -> Void
    
    @State private var isPressing = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("NRGRun")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, -20)
                
                Text("Time to take a gel pack!")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.top, 25)
                
                Text("Press and hold 3s to confirm")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                    .padding(.top, 8)
            }
        }
        .gesture(
            LongPressGesture(minimumDuration: 3.0)
                .onChanged { _ in
                    isPressing = true
                }
                .onEnded { _ in
                    WKInterfaceDevice.current().play(.success)
                    onConfirmHold()
                }
        )
    }
}
