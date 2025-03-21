import SwiftUI

struct HomeView: View {
    
    struct Run: Identifiable {
        let id = UUID()
        let date: Date
        let totalTimeInMinutes: Int
        let pace: Double
        let distance: Double
        let gels: Int
        
        var timeOfDayString: String {
            let hour = Calendar.current.component(.hour, from: date)
            if hour < 12 {
                return "Morning Run"
            } else if hour < 17 {
                return "Afternoon Run"
            } else {
                return "Evening Run"
            }
        }
        
        var fullDateString: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        var timeDisplay: String {
            let hours = totalTimeInMinutes / 60
            let minutes = totalTimeInMinutes % 60
            if hours > 0 {
                return "\(hours)h \(minutes)min"
            } else {
                return "\(minutes)min"
            }
        }
    }
    
    @State private var runs: [Run] = [
        Run(date: makeDate(year: 2025, month: 3, day: 23, hour: 15, minute: 23), totalTimeInMinutes: 109, pace: 5.29, distance: 20.0, gels: 3),
        Run(date: makeDate(year: 2025, month: 3, day: 17, hour: 19, minute: 9), totalTimeInMinutes: 172, pace: 5.55, distance: 31, gels: 4),
        Run(date: makeDate(year: 2025, month: 3, day: 2, hour: 14, minute: 0), totalTimeInMinutes: 134, pace: 6.00, distance: 22.4, gels: 3),
        Run(date: makeDate(year: 2025, month: 2, day: 27, hour: 8, minute: 30), totalTimeInMinutes: 75, pace: 4.75, distance: 15.6, gels: 2) // 4th run added
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // -- Header (Stays Fixed) --
                HStack {
                    Image("NRGLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 60)
//                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                .background(Color.black)

                // -- Scrollable Content (Starts Lower) --
                ScrollView {
                    VStack(spacing: 16) {
                        
                        ForEach(runs) { run in
                            RunCard(run: run)
                        }
                        
                        Color.clear.frame(height: 60) // Ensures last card isn't too close to footer
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .padding(.top, 20)
                .padding(.bottom, 15)// Pushes the whole scroll view lower
            
            }
        }
    }
}

struct RunCard: View {
    let run: HomeView.Run

    @State private var isPressed = false // For hover effect

    var body: some View {
        NavigationLink(destination: RunDetailView(run: run)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "figure.run")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                    
                    Text(run.fullDateString)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Text(run.timeOfDayString)
                    .font(.title2)
                    .foregroundColor(.white)
                    .bold()
                
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Text(run.timeDisplay)
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Distance")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Text(String(format: "%.2f km", run.distance))
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pace")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(paceString(from: run.pace)) /km")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Gels Taken")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            Text(run.gels == 1 ? "1 gel" : "\(run.gels) gels")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isPressed ? Color.gray.opacity(0.3) : Color(red: 0.15, green: 0.15, blue: 0.15))
            .cornerRadius(12)
            .shadow(radius: 5)
            .scaleEffect(isPressed ? 0.98 : 1.0) // Slight press animation
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle()) // Removes default NavigationLink style
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private func paceString(from decimalPace: Double) -> String {
        let minutes = Int(decimalPace)
        let fractional = decimalPace - Double(minutes)
        let seconds = Int(fractional * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
}

fileprivate func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? Date()
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
