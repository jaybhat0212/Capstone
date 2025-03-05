import SwiftUI

struct MetricsView: View {
    @Binding var elapsedTime: TimeInterval
    let pace: Double?
    @Binding var heartRate: Double?                   // New binding for heart rate
    @Binding var heartRateVariability: Double?
    let vo2: Double?                                  // New parameter for VO₂
    @Binding var grade: Double
    // Gel time passed as a TimeInterval (in seconds).
    let lastGelTime: TimeInterval
    let totalDistance: Double
    let runningSpeed: Double?
    let totalCaloriesBurned: Double
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetricRow(title: "Elapsed Time", value: formatTime(elapsedTime))
                MetricRow(title: "Distance", value: String(format: "%.2f km", totalDistance / 1000.0))
                MetricRow(title: "Pace", value: pace != nil ? String(format: "%.2f km/h", pace!) : "--")
                MetricRow(title: "Running Speed", value: runningSpeed != nil ? String(format: "%.2f m/s", runningSpeed!) : "--")
                // New: Heart Rate row.
                MetricRow(title: "Heart Rate", value: heartRate != nil ? String(format: "%.0f bpm", heartRate!) : "--")
                MetricRow(title: "HRV", value: heartRateVariability != nil ? String(format: "%.0f ms", heartRateVariability!) : "--")
                // New: VO₂ row.
                MetricRow(title: "VO₂", value: vo2 != nil ? String(format: "%.1f ml/kg·min", vo2!) : "--")
                MetricRow(title: "HRV", value: heartRateVariability != nil ? String(format: "%.0f", heartRateVariability!) : "--")
                MetricRow(title: "Grade", value: String(format: "%.2f", grade))
                // Display the gel consumption time in HH:mm:ss. If no gel, show "00:00:00".
                MetricRow(title: "Last Gel", value: lastGelTime > 0 ? formatGelTime(lastGelTime) : "00:00:00")
                MetricRow(title: "Calories Burned", value: String(format: "%.0f kcal", totalCaloriesBurned))
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Formats a TimeInterval as HH:mm:ss.
    func formatGelTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
        }
    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        MetricsView(
            elapsedTime: .constant(125),
            pace: 10.0,
            heartRate: .constant(72),
            heartRateVariability: .constant(75),
            vo2: 35.0,
            grade: .constant(0.05),
            lastGelTime: 3500,
            totalDistance: 3500,
            runningSpeed: 3.5,
            totalCaloriesBurned: 150
        )
    }
}
