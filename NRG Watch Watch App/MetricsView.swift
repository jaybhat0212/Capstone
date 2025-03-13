//
//  WatchMetricsView.swift
//  NRG
//

import SwiftUI
import Combine

struct MetricsView: View {
    @Binding var elapsedTime: TimeInterval
    let pace: Double?

    @Binding var heartRateVariability: Double?
    @Binding var heartRate: Double?
    @Binding var vo2Max: Double?
    @Binding var grade: Double

    let lastGelTime: TimeInterval
    let totalDistance: Double
    let runningSpeed: Double?
    let totalCaloriesBurned: Double

    // NEW: Display phone-synced gel serving
    @Binding var gelServing: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1) Time & Distance
                MetricRow(title: "Elapsed Time", value: formatTime(elapsedTime))
                MetricRow(title: "Distance", value: String(format: "%.2f km", totalDistance / 1000.0))

                // 2) Pace & Speed
                MetricRow(
                    title: "Pace",
                    value: pace != nil ? String(format: "%.2f km/h", pace!) : "--"
                )
                MetricRow(
                    title: "Running Speed",
                    value: runningSpeed != nil ? String(format: "%.2f m/s", runningSpeed!) : "--"
                )

                // 3) HRV & Heart Rate
                MetricRow(
                    title: "HRV",
                    value: heartRateVariability != nil ? String(format: "%.0f ms", heartRateVariability!) : "--"
                )
                MetricRow(
                    title: "Heart Rate",
                    value: heartRate != nil ? String(format: "%.0f BPM", heartRate!) : "--"
                )

                // 4) VO₂ Max
                MetricRow(
                    title: "VO₂ Max",
                    value: vo2Max != nil
                           ? String(format: "%.1f ml/kg/min", vo2Max!)
                           : "--"
                )

                // 5) Grade & Last Gel
                MetricRow(
                    title: "Grade",
                    value: String(format: "%.2f", grade)
                )
                MetricRow(
                    title: "Last Gel",
                    value: lastGelTime > 0 ? formatGelTime(lastGelTime) : "00:00:00"
                )

                // 6) Calories
                MetricRow(
                    title: "Calories Burned",
                    value: String(format: "%.0f kcal", totalCaloriesBurned)
                )

                // 7) Gel Serving
                MetricRow(
                    title: "Gel Serving",
                    value: "\(gelServing) cal"
                )
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Helpers
func formatTime(_ interval: TimeInterval) -> String {
    let minutes = Int(interval) / 60
    let seconds = Int(interval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

func formatGelTime(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    let seconds = Int(interval) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

// Reusable row
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
