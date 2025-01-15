//
//  ContentView.swift
//  NRG
//
//  Created by Jay Bhatasana on 2024-07-19.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthStoreManager: HealthStoreManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HealthDataCard(title: "Steps", value: "\(Int(healthStoreManager.steps))")
                HealthDataCard(title: "Speed", value: String(format: "%.2f m/s", healthStoreManager.speed))
                HealthDataCard(title: "Body Weight", value: String(format: "%.2f kg", healthStoreManager.bodyWeight))
                HealthDataCard(title: "Resting VO2", value: String(format: "%.2f ml/(kg*min)", healthStoreManager.restingVO2))
                HealthDataCard(title: "HRV", value: String(format: "%.2f ms", healthStoreManager.heartRateVariability))
                HealthDataCard(title: "Elevation Change", value: String(format: "%.2f flights", healthStoreManager.elevationChange))
            }
            .padding()
        }
        .onAppear {
            healthStoreManager.checkAuthorization()
        }
    }
}

struct HealthDataCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(value)
                .font(.title)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(HealthStoreManager())
    }
}
