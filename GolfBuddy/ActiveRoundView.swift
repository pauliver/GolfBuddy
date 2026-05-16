import SwiftUI
import SwiftData
import CoreLocation

struct ActiveRoundView: View {
    let round: GolfRound
    let locationManager: LocationManager

    private var currentHole: GolfHole? {
        round.course?.sortedHoles.first { $0.number == round.currentHoleNumber }
    }

    private var centerYards: Int? {
        guard let coord = currentHole?.pinCoordinate,
              let d = locationManager.distanceInYards(to: coord) else { return nil }
        return Int(d.rounded())
    }
    private var frontYards:  Int? { centerYards.map { max(0, $0 - 15) } }
    private var backYards:   Int? { centerYards.map { $0 + 15 } }

    private var currentScore: HoleScore? { round.scoreForHole(round.currentHoleNumber) }
    private var currentStrokes: Int { currentScore?.strokes ?? 0 }
    private var currentPutts:   Int { currentScore?.putts   ?? 0 }
    private var currentFairway: Bool? { currentScore?.fairwayHit }

    private var isParThree: Bool { (currentHole?.par ?? 4) == 3 }
    private var totalHoles: Int { round.course?.holeCount ?? 18 }
    private var isLastHole: Bool { round.currentHoleNumber >= totalHoles }

    var body: some View {
        ZStack {
            Color.golfPaper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    holeHeader
                    Divider().overlay(Color.golfInk.opacity(0.08))
                    distanceSection
                    Divider().overlay(Color.golfInk.opacity(0.08))
                    if let hole = currentHole, hole.hasPinCoordinates || hole.hasTeeCoordinates {
                        HoleMapView(hole: hole, userLocation: locationManager.location)
                            .frame(height: 200)
                        Divider().overlay(Color.golfInk.opacity(0.08))
                    }
                    scoreSection
                    advanceSection
                }
            }
        }
        .onAppear {
            setupWatchHandler()
            ConnectivityManager.shared.sendRoundState(round.watchPayload())
        }
        .onDisappear { ConnectivityManager.shared.onWatchMessage = nil }
    }

    // MARK: - Header

    private var holeHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text((round.course?.name ?? "").uppercased())
                    .font(.golfMono(size: 10)).foregroundStyle(Color.golfInkMute).tracking(1.5)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Hole \(round.currentHoleNumber)")
                        .font(.system(size: 30, weight: .bold)).foregroundStyle(Color.golfInk)
                    if let h = currentHole {
                        Text("Par \(h.par)")
                            .font(.golfMono(size: 16)).foregroundStyle(Color.golfFairway)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("TOTAL")
                    .font(.golfMono(size: 9)).foregroundStyle(Color.golfInkMute).tracking(1.5)
                let diff = round.scoreVsPar
                Text(round.totalStrokes == 0 ? "—" : (diff == 0 ? "E" : (diff > 0 ? "+\(diff)" : "\(diff)")))
                    .font(.system(size: 22, weight: .semibold).monospacedDigit())
                    .foregroundStyle(diff == 0 ? Color.golfInk : scoreColor(diff))
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 16)
        .background(Color.golfPaper)
    }

    // MARK: - Distance (F / C / B)

    private var distanceSection: some View {
        VStack(spacing: 4) {
            if let c = centerYards {
                Text("\(c)")
                    .font(.system(size: 88, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.golfInk)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text("YARDS TO PIN")
                    .font(.golfMono(size: 10)).foregroundStyle(Color.golfInkMute).tracking(1.8)
            } else if let h = currentHole, h.yardage > 0 {
                Text("\(h.yardage)")
                    .font(.system(size: 88, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.golfInkMute)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text("YARDS (STORED)")
                    .font(.golfMono(size: 10)).foregroundStyle(Color.golfInkMute).tracking(1.8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "location.slash").font(.title2).foregroundStyle(Color.golfInkMute)
                    Text("No distance data").font(.golfMono(size: 12)).foregroundStyle(Color.golfInkMute)
                }
                .padding(.vertical, 12)
            }

            if let f = frontYards, let b = backYards {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("FRONT").font(.golfMono(size: 9)).foregroundStyle(Color.golfInkMute).tracking(1)
                        Text("\(f)").font(.system(size: 22, weight: .semibold).monospacedDigit()).foregroundStyle(Color.golfInkSoft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("BACK").font(.golfMono(size: 9)).foregroundStyle(Color.golfInkMute).tracking(1)
                        Text("\(b)").font(.system(size: 22, weight: .semibold).monospacedDigit()).foregroundStyle(Color.golfInkSoft)
                    }
                }
                .padding(.horizontal, 28).padding(.top, 4)
            }

            // Hazards
            if let h = currentHole, !h.features.filter({ $0.type != .green }).isEmpty {
                VStack(spacing: 8) {
                    ForEach(hazardDistances(), id: \.id) { hazard in
                        HStack {
                            Text(hazard.name.uppercased())
                                .font(.golfMono(size: 10)).foregroundStyle(Color.golfInkMute).tracking(1)
                            Spacer()
                            Text("\(hazard.distance)")
                                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                                .foregroundStyle(Color.golfInkSoft)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)
            }

            if locationManager.location != nil, let h = currentHole, !h.hasPinCoordinates, centerYards == nil {

                Button { recordPin() } label: {
                    Label("Record Pin Location", systemImage: "flag.fill")
                        .font(.footnote.weight(.medium)).foregroundStyle(Color.golfMoss)
                        .padding(.vertical, 6).padding(.horizontal, 14)
                        .background(Color.golfMoss.opacity(0.1), in: Capsule())
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20).padding(.horizontal, 22)
        .background(Color.golfPaper2)
    }

    // MARK: - Score entry

    private var scoreSection: some View {
        VStack(spacing: 20) {
            // Large score display
            if currentStrokes > 0, let h = currentHole {
                let diff = currentStrokes - h.par
                VStack(spacing: 0) {
                    Text("\(currentStrokes)")
                        .font(.golfSerif(size: 88)).foregroundStyle(scoreColor(diff)).monospacedDigit()
                    Text(scoreWord(diff, short: true))
                        .font(.golfSerif(size: 20, italic: true)).foregroundStyle(scoreColor(diff))
                }
                .padding(.top, 16)
            } else {
                Text("—")
                    .font(.system(size: 64, weight: .ultraLight)).foregroundStyle(Color.golfInkMute)
                    .padding(.top, 16)
            }

            VStack(spacing: 14) {
                // Strokes grid
                VStack(alignment: .leading, spacing: 6) {
                    Text("STROKES")
                        .font(.golfMono(size: 10)).foregroundStyle(Color.golfInkMute).tracking(1.6)
                        .padding(.horizontal, 22)
                    HStack(spacing: 6) {
                        ForEach(1...8, id: \.self) { n in
                            StrokeButton(n: n, selected: n == currentStrokes, accent: Color.golfMoss) {
                                setScore(strokes: n, putts: min(currentPutts, n))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }

                // Putts grid
                VStack(alignment: .leading, spacing: 6) {
                    Text("OF WHICH, PUTTS")
                        .font(.golfMono(size: 10)).foregroundStyle(Color.golfInkMute).tracking(1.6)
                        .padding(.horizontal, 22)
                    HStack(spacing: 6) {
                        ForEach(0...4, id: \.self) { n in
                            StrokeButton(n: n, selected: n == currentPutts, accent: Color.golfInk) {
                                setScore(strokes: currentStrokes, putts: n)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                }

                // Fairway (par 4/5 only)
                if !isParThree {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FAIRWAY")
                            .font(.golfMono(size: 10)).foregroundStyle(Color.golfInkMute).tracking(1.6)
                            .padding(.horizontal, 22)
                        HStack(spacing: 8) {
                            fairwayButton(label: "Hit", icon: "checkmark", value: true,
                                          selected: currentFairway == true, accent: Color.golfFairway)
                            fairwayButton(label: "Missed", icon: "xmark", value: false,
                                          selected: currentFairway == false, accent: Color.golfPin)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color.golfPaper)
    }

    // MARK: - Advance

    private var advanceSection: some View {
        VStack(spacing: 10) {
            Button(action: advanceHole) {
                Text(isLastHole ? "Finish Round" : "Save & advance to hole \(round.currentHoleNumber + 1)")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.golfMoss).foregroundStyle(Color.golfPaper)
                    .clipShape(Capsule())
            }
            Button(role: .destructive) {
                round.isComplete = true
                ConnectivityManager.shared.sendNoActiveRound()
            } label: {
                Text("Abandon Round").font(.subheadline).foregroundStyle(Color.golfPin)
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 20)
        .background(Color.golfPaper)
    }

    // MARK: - Actions

    struct HazardDistance: Identifiable {
        let id = UUID()
        let name: String
        let distance: Int
    }

    private func hazardDistances() -> [HazardDistance] {
        guard let loc = locationManager.location, let hole = currentHole else { return [] }
        var distances: [HazardDistance] = []

        let hazards = hole.features.filter { $0.type != .green }

        for feature in hazards {
            // Find closest point of hazard
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

        return distances.sorted { $0.distance < $1.distance }.prefix(3).map { $0 }
    }

    private func setScore(strokes: Int, putts: Int, fairwayHit: Bool? = nil) {

        let fw = fairwayHit ?? currentFairway
        round.setScore(holeNumber: round.currentHoleNumber, strokes: strokes, putts: putts, fairwayHit: fw)
        ConnectivityManager.shared.sendRoundState(round.watchPayload())
    }

    private func setFairway(_ hit: Bool) {
        round.setScore(holeNumber: round.currentHoleNumber,
                       strokes: currentStrokes, putts: currentPutts, fairwayHit: hit)
        ConnectivityManager.shared.sendRoundState(round.watchPayload())
    }

    private func advanceHole() {
        if isLastHole {
            round.isComplete = true
            ConnectivityManager.shared.sendNoActiveRound()
        } else {
            round.currentHoleNumber += 1
            ConnectivityManager.shared.sendRoundState(round.watchPayload())
        }
    }

    private func recordPin() {
        guard let loc = locationManager.location, let hole = currentHole else { return }
        hole.pinLatitude = loc.coordinate.latitude
        hole.pinLongitude = loc.coordinate.longitude
        hole.hasPinCoordinates = true
    }

    private func setupWatchHandler() {
        ConnectivityManager.shared.onWatchMessage = { message in
            guard let action = message["action"] as? String else { return }
            switch action {
            case "setScore":
                if let h = message["hole"] as? Int, let s = message["strokes"] as? Int, let p = message["putts"] as? Int {
                    let fw = message["fairwayHit"] as? Bool
                    round.setScore(holeNumber: h, strokes: s, putts: p, fairwayHit: fw)
                    ConnectivityManager.shared.sendRoundState(round.watchPayload())
                }
            case "nextHole":
                if round.currentHoleNumber < (round.course?.holeCount ?? 18) {
                    round.currentHoleNumber += 1
                } else { round.isComplete = true }
                ConnectivityManager.shared.sendRoundState(round.watchPayload())
            case "endRound":
                round.isComplete = true
                ConnectivityManager.shared.sendNoActiveRound()
            default: break
            }
        }
    }

    // MARK: - Subviews

    private func fairwayButton(label: String, icon: String, value: Bool, selected: Bool, accent: Color) -> some View {
        Button { setFairway(value) } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption)
                Text(label).font(.system(size: 14, weight: .medium))
            }
            .frame(width: 100, height: 44)
            .background(selected ? accent : Color.golfPaper2)
            .foregroundStyle(selected ? Color.golfPaper : Color.golfInk)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stroke/putt button

private struct StrokeButton: View {
    let n: Int
    let selected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(n)")
                .font(.golfMono(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(selected ? accent : Color.golfPaper2)
                .foregroundStyle(selected ? Color.golfPaper : Color.golfInk)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
