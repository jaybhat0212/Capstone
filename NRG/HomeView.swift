import SwiftUI

struct HomeView: View {
    
    // Simple Run model for demo purposes
    struct Run: Identifiable {
        let id = UUID()
        let date: Date
        let totalTimeInMinutes: Int
        let pace: Double
        let distance: Double
        let gels: Int
        
        // e.g. "Morning Run", "Afternoon Run", or "Evening Run"
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
        
        // e.g. "Jan 2, 2025 at 7:09 PM"
        var fullDateString: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        // For display: "1h 51m" or "45m" etc.
        var timeDisplay: String {
            let hours = totalTimeInMinutes / 60
            let minutes = totalTimeInMinutes % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
    
    // Hard-coded demo data
    @State private var runs: [Run] = [
        Run(
            date: makeDate(year: 2025, month: 1, day: 1, hour: 9, minute: 14),
            totalTimeInMinutes: 23,
            pace: 4.55,    // e.g. 4:33 /km => 4.55 in decimal
            distance: 5.22,
            gels: 1
        ),
        Run(
            date: makeDate(year: 2025, month: 1, day: 2, hour: 19, minute: 9),
            totalTimeInMinutes: 111,
            pace: 5.55,    // e.g. 5:33 /km => 5.55 in decimal
            distance: 20.8,
            gels: 3
        ),
        Run(
            date: makeDate(year: 2025, month: 1, day: 2, hour: 14, minute: 0),
            totalTimeInMinutes: 45,
            pace: 5.00,
            distance: 7.3,
            gels: 2
        )
    ]
    
    var body: some View {
        ZStack {
            // Entire page background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Grey header bar with NRG logo at top-left
                HStack {
                    Image("NRGLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                        .padding(.leading, 16)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.gray)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(runs) { run in
                            RunCard(run: run)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
    }
}

// A card to display run information in the style shown in the provided image
struct RunCard: View {
    let run: HomeView.Run
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Top row: date/time + optional run icon
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                
                Text(run.fullDateString)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Second row: "Morning Run" / "Afternoon Run" / "Evening Run"
            Text(run.timeOfDayString)
                .font(.title3)
                .foregroundColor(.white)
                .bold()
            
            // Stats laid out in two rows, with two columns each:
            // Row 1: Time - Distance
            // Row 2: Pace - Gels Taken
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(run.timeDisplay)
                        .foregroundColor(.white)
                        .font(.body)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.2f km", run.distance))
                        .foregroundColor(.white)
                        .font(.body)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pace")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    // Format e.g. "5:33 /km". If run.pace is 5.55, let's do "5:33" style
                    Text("\(paceString(from: run.pace)) /km")
                        .foregroundColor(.white)
                        .font(.body)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gels Taken")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(run.gels) gels")
                        .foregroundColor(.white)
                        .font(.body)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        // Card background a dark grey (near-black) for contrast
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
    
    // Helper to format decimal pace into m:ss
    private func paceString(from decimalPace: Double) -> String {
        // e.g. 5.55 => 5 minutes + 0.55 * 60 = 33 seconds => "5:33"
        let minutes = Int(decimalPace)
        let fractional = decimalPace - Double(minutes)
        let seconds = Int(fractional * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// A helper for making Date objects quickly – for demo data only.
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
