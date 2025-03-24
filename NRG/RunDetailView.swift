import SwiftUI

struct RunDetailView: View {
    let run: HomeView.Run
    // Define a margin to inset the graph area.
    let margin: CGFloat = 16
    // Shared state for the selected gel marker (if any), used by both the graph and the gel split list.
    @State private var selectedGelIndex: Int? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            
            // Run Details
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Header (date and icon)
                    HStack {
                        Image(systemName: "figure.run")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.white)
                        Text(run.fullDateString)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    // Run title
                    Text(run.timeOfDayString)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    // Graph with tooltip overlay placed outside of the graph area.
                    ZStack(alignment: .top) {
                        RunGraphView(run: run, margin: margin, selectedGelIndex: $selectedGelIndex)
                            .frame(height: 300)
                            .cornerRadius(12)
                        // Tooltip view is placed above the graph.
                        RunGraphTooltip(run: run, margin: margin, selectedGelIndex: $selectedGelIndex)
                    }
                    
                    // Gel Split Section
                    Text("Gel Split")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        ForEach(run.gelSplits.indices, id: \.self) { index in
                            let split = run.gelSplits[index]
                            // Wrap each gel split cell in a long-press gesture.
                            GelSplitRow(gelNumber: index + 1,
                                        distance: String(format: "%.2f km", split.distance),
                                        time: "\(Int(split.time))m")
                                .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                                    // The gel split cells correspond to dataPoints index = cell index + 1.
                                    if pressing {
                                        selectedGelIndex = index + 1
                                    } else {
                                        selectedGelIndex = nil
                                    }
                                }, perform: {})
                        }
                    }
                    .padding()
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(12)
                    
                    // Run Stats
                    RunStatsView(run: run)
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
}

// MARK: - Gel Split Row

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

// MARK: - Run Stats View

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
                    Text("\(paceString(from: run.pace)) /km")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Heart Rate")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(run.avgHeartRate) bpm")
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

// MARK: - RunGraphView

struct RunGraphView: View {
    let run: HomeView.Run
    let margin: CGFloat
    // Build data points: origin, each gel split, and final point.
    private var dataPoints: [CGPoint] {
        let splits = run.gelSplits.map { CGPoint(x: $0.time, y: $0.distance) }
        return [CGPoint(x: 0, y: 0)] + splits + [CGPoint(x: Double(run.totalTimeInMinutes), y: run.distance)]
    }
    
    // Animation state.
    @State private var lineProgress: CGFloat = 0.0
    @State private var cumulativeDistances: [CGFloat] = []
    @State private var totalDistance: CGFloat = 0.0
    // Binding to share which gel marker is selected.
    @Binding var selectedGelIndex: Int?
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let converted = convertedPoints(in: size)
            ZStack {
                Color.black.ignoresSafeArea()
                AxesView(dataPoints: dataPoints, margin: margin)
                AnimatedLineShape(convertedPoints: converted, progress: lineProgress)
                    .stroke(Color.white, lineWidth: 2)
                
                ForEach(dataPoints.indices, id: \.self) { i in
                    let fractionDistance = totalDistance > 0 ? (cumulativeDistances[i] / totalDistance) : 0
                    let isVisible = (lineProgress >= fractionDistance)
                    if isVisible {
                        if i == 0 || i == dataPoints.count - 1 {
                            // Origin and final points are non-interactive.
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .position(converted[i])
                        } else {
                            // Interactive gel marker.
                            // If this marker is selected, grow its size.
                            let markerSize: CGFloat = (selectedGelIndex == i) ? 80 : 40
                            Image("Lightning")
                                .resizable()
                                .scaledToFit()
                                .frame(width: markerSize, height: markerSize)
                                .position(converted[i])
                                .onLongPressGesture(minimumDuration: 0.5) {
                                    selectedGelIndex = i
                                } onPressingChanged: { pressing in
                                    if !pressing {
                                        selectedGelIndex = nil
                                    }
                                }
                        }
                    }
                }
            }
            .onAppear {
                let pts = convertedPoints(in: size)
                cumulativeDistances = computeCumulativeDistances(pts)
                totalDistance = cumulativeDistances.last ?? 0
                withAnimation(.easeOut(duration: 2.0)) {
                    lineProgress = 1.0
                }
            }
        }
        .frame(minHeight: 300)
    }
    
    private func convertedPoints(in size: CGSize) -> [CGPoint] {
        dataPoints.map { convertToViewCoordinates($0, in: size, margin: margin, allPoints: dataPoints) }
    }
}

// MARK: - RunGraphTooltip

struct RunGraphTooltip: View {
    let run: HomeView.Run
    let margin: CGFloat
    // Binding to know which gel marker (if any) is being held.
    @Binding var selectedGelIndex: Int?
    
    // Compute data points the same way as in RunGraphView.
    private var dataPoints: [CGPoint] {
        let splits = run.gelSplits.map { CGPoint(x: $0.time, y: $0.distance) }
        return [CGPoint(x: 0, y: 0)] + splits + [CGPoint(x: Double(run.totalTimeInMinutes), y: run.distance)]
    }
    
    // For tooltip positioning, convert the point using geometry.
    private func convertedPoint(for size: CGSize, at index: Int) -> CGPoint {
        convertToViewCoordinates(dataPoints[index], in: size, margin: margin, allPoints: dataPoints)
    }
    
    var body: some View {
        GeometryReader { geo in
            if let index = selectedGelIndex, index > 0, index < dataPoints.count - 1 {
                let point = convertedPoint(for: geo.size, at: index)
                // Tooltip offset: 40 points above the marker.
                let desiredY = point.y - 70
                // Ensure tooltip doesn't go off the top; if so, position it at margin+10.
                let tooltipY = desiredY < margin ? margin + 10 : desiredY
                let gelNumber = index  // dataPoints[1] is Gel #1.
                let gelSplit = run.gelSplits[gelNumber - 1]
                let distanceStr = String(format: "%.2f", gelSplit.distance)
                let timeStr = gelTimeString(for: gelSplit.time)
                
                VStack {
                    Text("Gel #\(gelNumber):")
                    Text("\(distanceStr) km, \(timeStr)")
                }
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(10)
                .background(Color.black.opacity(0.85))
                .cornerRadius(8)
                .fixedSize()
                .position(x: point.x, y: tooltipY)
            }
        }
    }
}

// MARK: - AnimatedLineShape

struct AnimatedLineShape: Shape {
    let convertedPoints: [CGPoint]
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard convertedPoints.count > 1 else { return path }
        path.move(to: convertedPoints[0])
        for pt in convertedPoints.dropFirst() {
            path.addLine(to: pt)
        }
        return path.trimmedPath(from: 0, to: progress)
    }
}

// MARK: - Helper Functions

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
            let segmentLength = sqrt(dx * dx + dy * dy)
            runningTotal += segmentLength
            distances.append(runningTotal)
        }
    }
    return distances
}

struct AxesView: View {
    let dataPoints: [CGPoint]
    let margin: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let plotWidth = width - 2 * margin
            let plotHeight = height - 2 * margin
            let minX = dataPoints.map(\.x).min() ?? 0
            let maxX = dataPoints.map(\.x).max() ?? 1
            let minY = dataPoints.map(\.y).min() ?? 0
            let maxY = dataPoints.map(\.y).max() ?? 1
            
            ZStack {
                // X-axis.
                Path { path in
                    path.move(to: CGPoint(x: margin, y: height - margin))
                    path.addLine(to: CGPoint(x: width - margin, y: height - margin))
                }
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                
                // Y-axis.
                Path { path in
                    path.move(to: CGPoint(x: margin, y: height - margin))
                    path.addLine(to: CGPoint(x: margin, y: margin))
                }
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                
                // X-axis ticks and labels.
                let xTicks = makeTicks(minValue: minX, maxValue: maxX, stepHint: 20)
                ForEach(xTicks, id: \.self) { tickVal in
                    let xFrac = normalize(value: tickVal, min: minX, max: maxX)
                    let x = margin + xFrac * plotWidth
                    Path { path in
                        path.move(to: CGPoint(x: x, y: height - margin))
                        path.addLine(to: CGPoint(x: x, y: height - margin - 6))
                    }
                    .stroke(Color.white, lineWidth: 1)
                    Text("\(Int(tickVal))")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .position(x: x, y: height - margin - 14)
                }
                
                // Y-axis ticks and labels.
                let yTicks = makeTicks(minValue: minY, maxValue: maxY, stepHint: 5)
                ForEach(yTicks, id: \.self) { tickVal in
                    let yFrac = normalize(value: tickVal, min: minY, max: maxY)
                    let yPos = margin + (plotHeight - yFrac * plotHeight)
                    Path { path in
                        path.move(to: CGPoint(x: margin, y: yPos))
                        path.addLine(to: CGPoint(x: margin + 6, y: yPos))
                    }
                    .stroke(Color.white, lineWidth: 1)
                    Text("\(Int(tickVal))")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .position(x: margin + 20, y: yPos)
                }
            }
        }
    }
}

fileprivate func convertToViewCoordinates(
    _ point: CGPoint,
    in size: CGSize,
    margin: CGFloat,
    allPoints: [CGPoint]
) -> CGPoint {
    let availableWidth = size.width - 2 * margin
    let availableHeight = size.height - 2 * margin
    let minX = allPoints.map(\.x).min() ?? 0
    let maxX = allPoints.map(\.x).max() ?? 1
    let minY = allPoints.map(\.y).min() ?? 0
    let maxY = allPoints.map(\.y).max() ?? 1
    let xFrac = normalize(value: point.x, min: minX, max: maxX)
    let yFrac = normalize(value: point.y, min: minY, max: maxY)
    let xPos = margin + xFrac * availableWidth
    let yPos = margin + (availableHeight - yFrac * availableHeight)
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

func paceString(from decimalPace: Double) -> String {
    let minutes = Int(decimalPace)
    let fractional = decimalPace - Double(minutes)
    let seconds = Int(round(fractional * 60))
    return String(format: "%d:%02d", minutes, seconds)
}

func gelTimeString(for minutes: Double) -> String {
    let hrs = Int(minutes) / 60
    let mins = Int(minutes) % 60
    return String(format: "%02d:%02d", hrs, mins)
}

struct RunDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RunDetailView(run: HomeView.Run(
            date: Date(),
            totalTimeInMinutes: 111,
            pace: 5.55,
            distance: 20.8,
            gels: 3,
            gelSplits: [
                (time: 32, distance: 5.23),
                (time: 65, distance: 12.23),
                (time: 102, distance: 18.85)
            ],
            avgHeartRate: 165
        ))
    }
}
