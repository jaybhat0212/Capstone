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
                VStack(alignment: .leading, spacing: 25) {
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
                    RunGraphView(run: run)

                    // -- Gel Split Section --
                    Text("Gel Split")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        GelSplitRow(gelNumber: 1, distance: "5.23km", time: "32m")
                        Divider().background(Color.white.opacity(0.3))
                        GelSplitRow(gelNumber: 2, distance: "12.23km", time: "1h 5m")
                        Divider().background(Color.white.opacity(0.3))
                        GelSplitRow(gelNumber: 3, distance: "18.85km", time: "1h 42m")
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
                    Text("165 bpm") // Hardcoded for now
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

struct RunGraphView: View {
    let run: HomeView.Run
    
    // 5 data points: (0,0), 3 gels, final anchor
    private var dataPoints: [CGPoint] {
        let gelData: [(Double, Double)] = [
            (32, 5.23),
            (65, 12.23),
            (102, 18.85)
        ]
        let all = [(0.0, 0.0)]
            + gelData
            + [(Double(run.totalTimeInMinutes), run.distance)]
        return all.map { CGPoint(x: $0.0, y: $0.1) }
    }
    
    // Our animation progress (0…1)
    @State private var lineProgress: CGFloat = 0.0
    
    // Distances along the path for each point
    @State private var cumulativeDistances: [CGFloat] = []
    @State private var totalDistance: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) Black background
                Color.black.ignoresSafeArea()
                
                // 2) Axes + Ticks
                AxesView(dataPoints: dataPoints)
                
                // 3) The animated line, trimmed 0..lineProgress
                AnimatedLineShape(
                    convertedPoints: convertedPoints(in: geo.size),
                    progress: lineProgress
                )
                .stroke(Color.white, lineWidth: 2)
                
                // 4) Each point appears as lineProgress passes it
                let converted = convertedPoints(in: geo.size)
                ForEach(dataPoints.indices, id: \.self) { i in
                    let fractionDistance = totalDistance > 0
                        ? (cumulativeDistances[i] / totalDistance)
                        : 0
                    let isVisible = (lineProgress >= fractionDistance)
                    
                    if isVisible {
                        // If the line is beyond this point's fraction,
                        // show the point
                        if i == 0 || i == dataPoints.count - 1 {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .transition(.scale)
                                .position(converted[i])
                        } else {
                            Image("Lightning")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .transition(.scale)
                                .position(converted[i])
                        }
                    }
                }
            }
            .onAppear {
                let points = convertedPoints(in: geo.size)
                let distances = computeCumulativeDistances(points)
                cumulativeDistances = distances
                totalDistance = distances.last ?? 0
                
                // Animate from 0..1
                withAnimation(.easeOut(duration: 2.0)) {
                    lineProgress = 1.0
                }
            }
        }
        .frame(minHeight: 300)
    }
    
    // Convert raw data to local geometry coords
    private func convertedPoints(in size: CGSize) -> [CGPoint] {
        dataPoints.map {
            convertToViewCoordinates($0, in: size, allPoints: dataPoints)
        }
    }
}

// MARK: - The distance-based shape

struct AnimatedLineShape: Shape {
    /// Points in local coordinates
    let convertedPoints: [CGPoint]
    
    /// 0…1 for how much of the path to draw
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard convertedPoints.count > 1 else { return path }
        
        // Build a full path
        path.move(to: convertedPoints[0])
        for pt in convertedPoints.dropFirst() {
            path.addLine(to: pt)
        }
        
        // Trim from 0..progress so if progress=0.5 => half the line is drawn
        return path.trimmedPath(from: 0, to: progress)
    }
}

// MARK: - Path distance measurement

/// Returns an array `distances`, where distances[i] is the path length
/// from the start (points[0]) up to points[i].
fileprivate func computeCumulativeDistances(_ points: [CGPoint]) -> [CGFloat] {
    guard points.count > 1 else { return [0] }
    
    var distances: [CGFloat] = []
    var runningTotal: CGFloat = 0
    
    for i in points.indices {
        if i == 0 {
            distances.append(0)
        } else {
            let dx = points[i].x - points[i-1].x
            let dy = points[i].y - points[i-1].y
            let segmentLength = sqrt(dx*dx + dy*dy)
            runningTotal += segmentLength
            distances.append(runningTotal)
        }
    }
    return distances
}

// MARK: - The Axes

struct AxesView: View {
    let dataPoints: [CGPoint]
    
    var body: some View {
        GeometryReader { geo in
            let minX = dataPoints.map(\.x).min() ?? 0
            let maxX = dataPoints.map(\.x).max() ?? 1
            let minY = dataPoints.map(\.y).min() ?? 0
            let maxY = dataPoints.map(\.y).max() ?? 1
            
            ZStack {
                // X-axis
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                }
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                
                // Y-axis
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                }
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                
                // Optional numeric ticks:
                let xTicks = makeTicks(minValue: minX, maxValue: maxX, stepHint: 20)
                let yTicks = makeTicks(minValue: minY, maxValue: maxY, stepHint: 5)
                
                // X-axis ticks + labels
                ForEach(xTicks, id: \.self) { tickVal in
                    let x = normalize(value: tickVal, min: minX, max: maxX) * geo.size.width
                    Path { path in
                        path.move(to: .init(x: x, y: geo.size.height))
                        path.addLine(to: .init(x: x, y: geo.size.height - 6))
                    }
                    .stroke(Color.white, lineWidth: 1)
                    
                    Text("\(Int(tickVal))")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .position(x: x, y: geo.size.height - 14)
                }
                
                // Y-axis ticks + labels
                ForEach(yTicks, id: \.self) { tickVal in
                    let yFrac = normalize(value: tickVal, min: minY, max: maxY)
                    let yPos = geo.size.height - (yFrac * geo.size.height)
                    
                    Path { path in
                        path.move(to: .init(x: 0, y: yPos))
                        path.addLine(to: .init(x: 6, y: yPos))
                    }
                    .stroke(Color.white, lineWidth: 1)
                    
                    Text("\(Int(tickVal))")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .position(x: 20, y: yPos)
                }
            }
        }
    }
}

// MARK: - Drawing the line

struct LineGraphShape: Shape {
    let dataPoints: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard dataPoints.count > 1 else { return path }
        
        let first = convertToViewCoordinates(dataPoints[0], in: rect.size, allPoints: dataPoints)
        path.move(to: first)
        
        for point in dataPoints.dropFirst() {
            let p = convertToViewCoordinates(point, in: rect.size, allPoints: dataPoints)
            path.addLine(to: p)
        }
        return path
    }
}

// MARK: - Coordinate Helpers

fileprivate func convertToViewCoordinates(
    _ point: CGPoint,
    in size: CGSize,
    allPoints: [CGPoint]
) -> CGPoint {
    let minX = allPoints.map(\.x).min() ?? 0
    let maxX = allPoints.map(\.x).max() ?? 1
    let minY = allPoints.map(\.y).min() ?? 0
    let maxY = allPoints.map(\.y).max() ?? 1
    
    let xFrac = normalize(value: point.x, min: minX, max: maxX)
    let yFrac = normalize(value: point.y, min: minY, max: maxY)
    
    let xPos = xFrac * size.width
    // Flip Y => bigger distances appear higher
    let yPos = size.height - (yFrac * size.height)
    return CGPoint(x: xPos, y: yPos)
}

fileprivate func normalize(value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    guard max > min else { return 0 }
    return (value - min) / (max - min)
}

fileprivate func makeTicks(minValue: CGFloat, maxValue: CGFloat, stepHint: CGFloat) -> [CGFloat] {
    let range = maxValue - minValue
    guard range > 0 else { return [minValue] }
    
    let stepCount = Int(ceil(range / stepHint))
    guard stepCount > 0 else { return [minValue, maxValue] }
    
    var ticks: [CGFloat] = []
    let step = range / CGFloat(stepCount)
    
    for i in 0...stepCount {
        let val = minValue + CGFloat(i) * step
        ticks.append(val.rounded())
    }
    return ticks
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
