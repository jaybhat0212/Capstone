import SwiftUI
import HealthKit

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
            
            if showError {
                Text("Unable to fetch your metrics from Health.")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                
                Text("We'll use a default resting VO2 of 3.5 ml/kg/min.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Please select your body weight:")
                Picker("Body Weight (kg)", selection: $selectedWeight) {
                    ForEach(40...140, id: \.self) { weight in
                        Text("\(weight) kg").tag(weight)
                    }
                }
                .labelsHidden()
                .frame(height: 50)
                .clipped()
                
                Button("Continue") {
                    restingVO2 = 3.5
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
        healthManager.requestAuthorization { success in
            guard success else {
                DispatchQueue.main.async {
                    showError = true
                }
                return
            }
            // Attempt to fetch VO2
            healthManager.fetchLatestData(for: .vo2Max,
                                          unit: HKUnit(from: "ml/kg*min")) { vo2 in
                DispatchQueue.main.async {
                    if let vo2 = vo2 {
                        restingVO2 = vo2
                    } else {
                        showError = true
                    }
                }
            }
            // Attempt to fetch BodyMass
            healthManager.fetchLatestData(for: .bodyMass,
                                          unit: .gramUnit(with: .kilo)) { mass in
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
}
