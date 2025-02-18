//
//  MainTrackingView.swift
//  NRG
//
//  Created by Jay Bhatasana on 2025-02-16.
//


import SwiftUI

struct MainTrackingView: View {
    @Binding var elapsedTime: TimeInterval
    var pace: Binding<Double?>
    @Binding var heartRateVariability: Double?
    
    // Manual gel intake callback
    let onTakenGel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                Text("Time: \(formatTime(elapsedTime))")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Pace: \(paceText)")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                Text("HRV: \(hrvText)")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
                Button("Taken Gel") {
                    onTakenGel()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    private var paceText: String {
        if let p = pace.wrappedValue {
            return String(format: "%.2f m/s", p)
        } else {
            return "--"
        }
    }
    
    private var hrvText: String {
        if let hrv = heartRateVariability {
            return String(format: "%.0f ms", hrv)
        } else {
            return "--"
        }
    }
    
    // Simple time formatter: MM:SS
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
