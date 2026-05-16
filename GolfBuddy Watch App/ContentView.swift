import SwiftUI
import CoreLocation

enum FeatureType: String, Codable {
    case bunker
    case water
    case green
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
}

struct HoleFeature: Codable {
    let type: FeatureType
    let coordinates: [Coordinate]
}


// MARK: - Watch design tokens (always-dark OLED)
private let W_INK:      Color = Color(watchHex: "F2ECDD")
private let W_DIM:      Color = Color(watchHex: "F2ECDD").opacity(0.5)
private let W_FAINT:    Color = Color(watchHex: "F2ECDD").opacity(0.18)
private let W_FAIRWAY:  Color = Color(watchHex: "6B8E5A")
private let W_FAIRWAY2: Color = Color(watchHex: "94B27E")
private let W_PIN:      Color = Color(watchHex: "E07A6D")

extension Color {
    init(watchHex hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(red:   Double((int >> 16) & 0xFF) / 255,
                  green: Double((int >> 8)  & 0xFF) / 255,
                  blue:  Double(int & 0xFF)          / 255)
    }
}

// MARK: - Root

struct ContentView: View {
    @State private var connectivity = WatchConnectivityManager.shared
    @State private var location     = WatchLocationManager()

    var body: some View {
        Group {
            if connectivity.hasActiveRound {
                ActiveHoleWatchView(connectivity: connectivity, location: location)
            } else {
                noRoundView
            }
        }
        .onAppear { location.start() }
    }

    private var noRoundView: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.golf")
                .font(.system(size: 36)).foregroundStyle(W_FAIRWAY2)
            Text("No Active Round")
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(W_INK)
            Text("Start from iPhone")
                .font(.system(size: 11)).foregroundStyle(W_DIM)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Active hole: Topo Green hero

struct ActiveHoleWatchView: View {
    @Bindable var connectivity: WatchConnectivityManager
    let location: WatchLocationManager

    @State private var showScore = false

    private var liveYards: Int? {
        guard connectivity.hasPinCoordinates,
              let d = location.distanceInYards(toLat: connectivity.pinLat, lon: connectivity.pinLon)
        else { return nil }
        return Int(d.rounded())
    }
    private var displayYards: Int { liveYards ?? connectivity.yardage }
    private var frontYards: Int { max(0, displayYards - 15) }
    private var backYards:  Int { displayYards + 15 }

    struct HazardDistance: Identifiable {
        let id = UUID()
        let name: String
        let distance: Int
    }

    private func hazardDistances() -> [HazardDistance] {
        guard let loc = location.currentLocation else { return [] }
        var distances: [HazardDistance] = []

        let hazards = features.filter { $0.type != .green }

        for feature in hazards {
            var minDistance: CLLocationDistance = .infinity
            for coord in feature.coordinates {
                let clCoord = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                let d = loc.distance(from: clCoord)
                if d < minDistance { minDistance = d }
            }
            let yards = Int((minDistance * 1.09361).rounded())
            let name = feature.type == .bunker ? "Bunker" : "Water"
            distances.append(HazardDistance(name: name, distance: yards))
        }

        return distances.sorted { $0.distance < $1.distance }.prefix(2).map { $0 }
    }

    var body: some View {

        if showScore {
            ScoreInputView(connectivity: connectivity) {
                showScore = false
                connectivity.sendNextHole()
            } onCancel: {
                showScore = false
            }
        } else {
            topoHeroView
        }
    }

    private var features: [HoleFeature] {
        guard let data = connectivity.featuresData else { return [] }
        return (try? JSONDecoder().decode([HoleFeature].self, from: data)) ?? []
    }

    private var topoHeroView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("HOLE \(connectivity.currentHole)  ·  PAR \(connectivity.par)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(W_FAIRWAY2).tracking(1.5)
                    .padding(.top, 4)

                Text("\(displayYards)")
                    .font(.system(size: 64, weight: .semibold).monospacedDigit())
                    .foregroundStyle(W_INK)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.top, 2)

                Text("YARDS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(W_DIM).tracking(1.8)

                // Topo green canvas
                Canvas { ctx, size in
                    let cx = size.width / 2
                    let cy = size.height * 0.52

                    if let green = features.first(where: { $0.type == .green }) {
                        // Very rough scaling just to show shape
                        let lats = green.coordinates.map { $0.latitude }
                        let lons = green.coordinates.map { $0.longitude }
                        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
                        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
                        let centerLat = (minLat + maxLat) / 2
                        let centerLon = (minLon + maxLon) / 2

                        let scaleLat = size.height / max((maxLat - minLat), 0.0001) * 0.6
                        let scaleLon = size.width / max((maxLon - minLon), 0.0001) * 0.6
                        let scale = min(scaleLat, scaleLon)

                        var p = Path()
                        for (i, coord) in green.coordinates.enumerated() {
                            let x = cx + (coord.longitude - centerLon) * scale
                            let y = cy - (coord.latitude - centerLat) * scale // inverted Y
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        p.closeSubpath()
                        ctx.stroke(p, with: .color(W_FAIRWAY), lineWidth: 1.5)
                        ctx.fill(p, with: .color(W_FAIRWAY.opacity(0.3)))
                    } else {
                        // Fallback concentric rings
                        let radii: [CGFloat] = [14, 24, 36, 48, 60]
                        for (i, r) in radii.enumerated() {
                            var p = Path()
                            p.addEllipse(in: CGRect(x: cx - r * 1.6, y: cy - r * 0.8,
                                                    width: r * 3.2, height: r * 1.6))
                            ctx.stroke(p, with: .color(W_FAIRWAY.opacity(0.35 - Double(i) * 0.05)), lineWidth: 0.7)
                        }
                    }

                    ctx.stroke(Path { p in
                        p.move(to: CGPoint(x: cx, y: cy))
                        p.addLine(to: CGPoint(x: cx, y: cy - 22))
                    }, with: .color(W_PIN), style: StrokeStyle(lineWidth: 1.2))
                    ctx.fill(Path { p in
                        p.move(to: CGPoint(x: cx, y: cy - 22))
                        p.addLine(to: CGPoint(x: cx + 12, y: cy - 18))
                        p.addLine(to: CGPoint(x: cx, y: cy - 14))
                        p.closeSubpath()
                    }, with: .color(W_PIN))
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - 2.5, y: cy - 2.5, width: 5, height: 5)), with: .color(W_PIN))
                }
                .frame(maxWidth: .infinity).frame(height: 70)

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("F").font(.system(size: 9, design: .monospaced)).foregroundStyle(W_DIM)
                        Text("\(frontYards)").font(.system(size: 28, weight: .semibold).monospacedDigit()).foregroundStyle(W_FAIRWAY2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("B").font(.system(size: 9, design: .monospaced)).foregroundStyle(W_DIM)
                        Text("\(backYards)").font(.system(size: 28, weight: .semibold).monospacedDigit()).foregroundStyle(W_FAIRWAY2)
                    }
                }
                .padding(.horizontal, 10)

                // Hazard distances
                let hazards = features.filter { $0.type != .green }
                if !hazards.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(hazardDistances(), id: \.id) { hazard in
                            HStack {
                                Text(hazard.name.uppercased())
                                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(W_DIM).tracking(1)
                                Spacer()
                                Text("\(hazard.distance)")
                                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
                                    .foregroundStyle(W_INK)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                }

                Button { showScore = true } label: {

                    Text("Record Score")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 7)
                        .background(W_FAIRWAY).foregroundStyle(W_INK)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8).padding(.bottom, 4)
            }
        }
    }
}

// MARK: - Score input

struct ScoreInputView: View {
    @Bindable var connectivity: WatchConnectivityManager
    var onDone: () -> Void
    var onCancel: () -> Void

    @State private var strokes: Int = 0
    @State private var putts:   Int = 0
    @State private var fairway: Bool? = nil

    private var par: Int { connectivity.par }
    private var isParThree: Bool { par == 3 }
    private var diff: Int { strokes - par }
    private var isLastHole: Bool { connectivity.currentHole >= connectivity.totalHoles }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 8) {
                    // Header
                    HStack {
                        Button("Cancel", action: onCancel)
                            .font(.system(size: 12)).foregroundStyle(W_DIM).buttonStyle(.plain)
                        Spacer()
                        Text("H\(connectivity.currentHole) · P\(par)")
                            .font(.system(size: 10, design: .monospaced)).foregroundStyle(W_FAIRWAY2)
                    }
                    .padding(.horizontal, 8)

                    // Score display
                    if strokes > 0 {
                        VStack(spacing: 0) {
                            Text("\(strokes)")
                                .font(.system(size: 44, weight: .bold).monospacedDigit())
                                .foregroundStyle(watchScoreColor(diff))
                            Text(watchScoreWord(diff))
                                .font(.system(size: 11))
                                .foregroundStyle(watchScoreColor(diff))
                        }
                    } else {
                        Text("—").font(.system(size: 36, weight: .ultraLight)).foregroundStyle(W_DIM)
                    }

                    // Strokes
                    gridLabel("STROKES")
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 4), count: 4), spacing: 4) {
                        ForEach(1...8, id: \.self) { n in
                            WatchNumButton(n: n, selected: n == strokes, accent: W_FAIRWAY) {
                                strokes = n; putts = min(putts, n)
                                connectivity.sendScoreUpdate(hole: connectivity.currentHole, strokes: n, putts: putts, fairwayHit: fairway)
                            }
                        }
                    }
                    .padding(.horizontal, 8)

                    // Putts
                    gridLabel("PUTTS")
                    HStack(spacing: 4) {
                        ForEach(0...4, id: \.self) { n in
                            WatchNumButton(n: n, selected: n == putts, accent: W_INK.opacity(0.8)) {
                                putts = n
                                connectivity.sendScoreUpdate(hole: connectivity.currentHole, strokes: strokes, putts: n, fairwayHit: fairway)
                            }
                        }
                    }
                    .padding(.horizontal, 8)

                    // Fairway (par 4/5 only)
                    if !isParThree {
                        gridLabel("FAIRWAY")
                        HStack(spacing: 6) {
                            fairwayToggle(label: "Hit", value: true,  selected: fairway == true,  accent: W_FAIRWAY)
                            fairwayToggle(label: "Miss", value: false, selected: fairway == false, accent: W_PIN)
                        }
                        .padding(.horizontal, 8)
                    }

                    // Done
                    Button(action: onDone) {
                        Text(isLastHole ? "Finish" : "Next →")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 7)
                            .background(strokes > 0 ? W_FAIRWAY : W_FAINT)
                            .foregroundStyle(W_INK)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain).disabled(strokes == 0)
                    .padding(.horizontal, 8).padding(.bottom, 4)
                }
                .padding(.top, 6)
            }
        }
        .onAppear {
            strokes = connectivity.currentHoleScore
            putts   = connectivity.currentHolePutts
            fairway = connectivity.currentHoleFairway
        }
        .onChange(of: connectivity.currentHole) { _, _ in
            strokes = connectivity.currentHoleScore
            putts   = connectivity.currentHolePutts
            fairway = connectivity.currentHoleFairway
        }
    }

    private func gridLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, design: .monospaced)).foregroundStyle(W_DIM).tracking(1.4)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
    }

    private func fairwayToggle(label: String, value: Bool, selected: Bool, accent: Color) -> some View {
        Button {
            fairway = selected ? nil : value   // tap again to deselect
            connectivity.sendScoreUpdate(hole: connectivity.currentHole, strokes: strokes, putts: putts, fairwayHit: fairway)
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity).frame(height: 32)
                .background(selected ? accent : Color.white.opacity(0.08))
                .foregroundStyle(selected ? (value ? Color.black : W_INK) : W_INK)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func watchScoreColor(_ diff: Int) -> Color {
        diff < 0 ? W_FAIRWAY2 : diff == 0 ? W_INK : W_PIN
    }

    private func watchScoreWord(_ diff: Int) -> String {
        switch diff {
        case ..<(-1): return "Eagle+"
        case -1: return "Birdie"
        case  0: return "Par"
        case  1: return "Bogey"
        case  2: return "Double"
        default: return "+\(diff)"
        }
    }
}

// MARK: - Number button

private struct WatchNumButton: View {
    let n: Int
    let selected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(n)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity).frame(height: 32)
                .background(selected ? accent : Color.white.opacity(0.08))
                .foregroundStyle(selected ? Color.black : W_INK)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview { ContentView() }
