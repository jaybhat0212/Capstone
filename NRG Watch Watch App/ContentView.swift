import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var isShowingFirstLaunch: Bool = true
    @State private var isMetricsReady: Bool = false
    @State private var restingVO2: Double? = nil
    @State private var bodyMass: Double? = nil
    @State private var elapsedTime: TimeInterval = 0
    @State private var runningSpeed: Double? = nil
    @State private var gradient: Double? = nil
    @State private var heartRate: Double? = nil
    
    private let healthManager = HealthManager()
    private let motionManager = MotionManager()
    
    @State private var startTime: Date? = nil
    @State private var timer: Timer? = nil
    
    var body: some View {
        if isShowingFirstLaunch {
            FirstLaunchView(
                isMetricsReady: $isMetricsReady,
                restingVO2: $restingVO2,
                bodyMass: $bodyMass
            )
            .onChange(of: isMetricsReady) { newValue in
                if newValue {
                    isShowingFirstLaunch = false
                }
            }
        } else {
            HomeView(
                
                startTracking: startTracking
                
            )
        }
    }
    
    func startTracking() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
        
        motionManager.startUpdates { speed, gradient, heartRate in
            DispatchQueue.main.async {
                runningSpeed = speed
                self.gradient = gradient
                self.heartRate = heartRate
            }
        }
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        motionManager.stopUpdates()
        elapsedTime = 0
    }
}

struct FirstLaunchView: View {
    @Binding var isMetricsReady: Bool
    @Binding var restingVO2: Double?
    @Binding var bodyMass: Double?
    
    @State private var showError: Bool = false
    @State private var selectedWeight: Int = 70
    
    private let healthManager = HealthManager()
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Welcome to NRG Watch App")
                .font(.headline)
            
            Text("Retrieving your metrics...")
                .onAppear(perform: fetchMetrics)
            
            // If there's no error, the user sees nothing else here.
            // If there's an error, we present a fallback UI:
            if showError {
                Text("Unable to fetch your metrics.")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                
                // Explain default VO2 usage
                Text("We'll use a default resting VO2 of 3.5 ml/kg/min. For better accuracy, please measure your actual resting VO2.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Body Weight Picker
                Text("Please select your body weight:")
                Picker("Body Weight (kg)", selection: $selectedWeight) {
                    ForEach(40...140, id: \.self) { weight in
                        Text("\(weight) kg").tag(weight)
                    }
                }
                .labelsHidden()
                .frame(height: 50)
                .clipped()
                
                // Confirm Button
                Button("Continue") {
                    // If restingVO2 wasn't fetched, use the default
                    if restingVO2 == nil {
                        restingVO2 = 3.5
                    }
                    // Use user-selected weight
                    bodyMass = Double(selectedWeight)
                    isMetricsReady = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    func fetchMetrics() {
        // Fetch VO2
        healthManager.fetchLatestData(for: .vo2Max, unit: HKUnit(from: "ml/kg*min")) { vo2 in
            DispatchQueue.main.async {
                if let vo2 = vo2 {
                    restingVO2 = vo2
                } else {
                    showError = true
                }
            }
        }
        
        // Fetch Body Mass
        healthManager.fetchLatestData(for: .bodyMass, unit: .gramUnit(with: .kilo)) { mass in
            DispatchQueue.main.async {
                if let mass = mass {
                    bodyMass = mass
                } else {
                    showError = true
                }
            }
        }
    }
}


struct MainView: View {
    @Binding var elapsedTime: TimeInterval
    @Binding var runningSpeed: Double?
    @Binding var gradient: Double?
    @Binding var heartRate: Double?
    
    let onStart: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("NRG Watch App")
                    .font(.headline)
                
                MetricRowView(title: "Elapsed Time", value: elapsedTime > 0 ? "\(formatTime(elapsedTime))" : "Not Started")
                MetricRowView(title: "Running Speed", value: runningSpeed != nil ? "\(String(format: "%.2f", runningSpeed!)) m/s" : "Loading...")
                MetricRowView(title: "Gradient", value: gradient != nil ? "\(String(format: "%.2f", gradient!)) °" : "Loading...")
                MetricRowView(title: "Heart Rate", value: heartRate != nil ? "\(String(format: "%.0f", heartRate!)) bpm" : "Loading...")
                
                Button(action: onStart) {
                    Text("Start")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: onStop) {
                    Text("Stop")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct HomeView: View {
    let startTracking: () -> Void
    @State private var isAnimating = false
    @State private var navigate = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image("NRGLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 60)
                        .padding(.leading, 7)
                    Spacer()
                }
                .padding(.top, -20)
                
                Spacer()
                
                Button(action: {
                    startTracking()
                    WKInterfaceDevice.current().play(.success) // ✅ Haptic Feedback
                    navigate = true // ✅ Navigate to TrackingView
                }) {
                    ZStack {
                        Circle() // Grey Circular Background
                            .fill(Color.gray.opacity(0.1)) // Light grey color
                            .frame(width: 120, height: 120) // Circle size
                        
                        Image(systemName: "play.fill") // Play icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 65, height: 65) // Icon size
                            .foregroundColor(Color.fromHex("#00FFC5"))
                            .scaleEffect(isAnimating ? 1.06 : 0.9) // Pulsating effect
                            .animation(Animation.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: isAnimating)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0) // Default size
                .onLongPressGesture(minimumDuration: 0.1) { // Subtle tap animation
                    withAnimation(.easeOut(duration: 0.1)) {
                        WKInterfaceDevice.current().play(.success) // Haptic Feedback
                    }
                }
                
                Text("START")
                    .font(.system(size: 27, weight: .bold))
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 1)
                
                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all)) // Black background
            
            .onAppear {
                isAnimating = true // Start pulsing animation when the view appears
            }
            
            .navigationDestination(isPresented: $navigate) {
                            TrackingView()
                        }
        }
    }
}

struct TrackingView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Background

            VStack {
                Spacer().frame(height: 10) // Add space from top
                
                // **Top Centered Logo**
                Image("NRGRun") // Make sure this matches the asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80) // Adjust size
                    .padding(.top, -30)
                
                Spacer() // Pushes everything else down
                
                
                HStack {
                    Spacer() // Pushes the icon to the right
                    Image("NRGHeart") // Ensure correct asset name in Xcode
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Adjust size
                        .padding(.trailing, 15) // Right padding
                        .padding(.bottom, 15) // Bottom padding
                }
            }
        }
    }
}

extension Color {
    static func fromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}

struct MetricRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.vertical, 5)
    }
}
