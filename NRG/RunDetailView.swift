import SwiftUI

struct RunDetailView: View {
    let run: HomeView.Run
    
    var body: some View {
        VStack(spacing: 0) {
            // -- Header (Always Black) --
            HStack {
                Image("NRGLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(Color.black)
            
            // -- Run Details --
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // -- Header (Run Date & Icon) --
                    HStack {
                        Image(systemName: "figure.run")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.white)
                        
                        Text(run.fullDateString)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    // -- Run Title --
                    Text(run.timeOfDayString)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    // -- Placeholder Graph --
                    RunGraphView()
                    
                    // -- Gel Split Section --
                    Text("Gel Split")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        GelSplitRow(gelNumber: 1, distance: "4km", time: "28m")
                        Divider().background(Color.white.opacity(0.3))
                        GelSplitRow(gelNumber: 2, distance: "9.5km", time: "1h 4m")
                        Divider().background(Color.white.opacity(0.3))
                        GelSplitRow(gelNumber: 3, distance: "16.8km", time: "1h 31m")
                    }
                    .padding()
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(12)
                    
                    // -- Run Stats --
                    RunStatsView(run: run)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
}

// --- Subview for Gel Split Rows ---
struct GelSplitRow: View {
    let gelNumber: Int
    let distance: String
    let time: String
    
    var body: some View {
        HStack {
            Text("Gel #\(gelNumber)")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Text("\(distance) (\(time))")
                .font(.title3)
                .foregroundColor(.white)
        }
    }
}

// --- Subview for Run Stats (Time, Distance, Pace, Heart Rate) ---
struct RunStatsView: View {
    let run: HomeView.Run
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text(run.timeDisplay)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Distance")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text(String(format: "%.2f km", run.distance))
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pace")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(paceString(from: run.pace)) /km") // ✅ This now works
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Heart Rate")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text("145 bpm") // Hardcoded for now
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
    }
}

// --- Subview for Placeholder Graph ---
struct RunGraphView: View {
    var body: some View {
        VStack {
            Text("Graph Placeholder")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 10)
            
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 200)
                .cornerRadius(12)
        }
        .padding()
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
    }
}

// --- ✅ Fix: Move paceString OUTSIDE of RunDetailView ---
func paceString(from decimalPace: Double) -> String {
    let minutes = Int(decimalPace)
    let fractional = decimalPace - Double(minutes)
    let seconds = Int(fractional * 60)
    return String(format: "%d:%02d", minutes, seconds)
}

// --- Preview ---
struct RunDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RunDetailView(run: HomeView.Run(
            date: Date(),
            totalTimeInMinutes: 111,
            pace: 5.55,
            distance: 20.8,
            gels: 3
        ))
    }
}
