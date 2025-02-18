import SwiftUI
import WatchKit

struct StopRunView: View {
    let onStopRun: () -> Void
    
    @State private var isPressing = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Only this flag will accept the 3s hold
                Image(systemName: "flag.checkered")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.red)
                    .gesture(
                        LongPressGesture(minimumDuration: 3.0)
                            .onChanged { _ in
                                isPressing = true
                            }
                            .onEnded { _ in
                                WKInterfaceDevice.current().play(.success)
                                onStopRun()
                            }
                    )
                
                Text("Hold 3s to Stop Run")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .padding(.top, 10)
            }
        }
    }
}
