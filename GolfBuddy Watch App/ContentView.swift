import SwiftUI
import MapKit
import CoreLocation

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
        WatchCourseDetectorView(location: location,
                                connectivity: connectivity)
    }
}

// MARK: - GPS course detector (no active round)

struct WatchCourseDetectorView: View {
    let location: WatchLocationManager
    let connectivity: WatchConnectivityManager

    struct Nearby: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
        let yards: Int
    }

    enum Phase: Equatable {
        case searching, empty, sent
        case found([Nearby])
        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.searching, .searching), (.empty, .empty), (.sent, .sent): return true
            case (.found(let a), .found(let b)): return a.count == b.count
            default: return false
            }
        }
    }

    @State private var phase: Phase = .searching
    @State private var phoneError = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 6) {
                Text("NEARBY COURSES")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(W_DIM).tracking(1.5)
                    .padding(.top, 6)

                switch phase {
                case .searching:
                    Spacer()
                    ProgressView().tint(W_FAIRWAY2)
                    Text("Searching…")
                        .font(.system(size: 11)).foregroundStyle(W_DIM)
                        .padding(.top, 4)
                    Spacer()

                case .found(let items):
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(items.prefix(4)) { item in
                                Button { tapped(item) } label: {
                                    HStack(spacing: 6) {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.name)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(W_INK)
                                                .lineLimit(2)
                                            Text("\(item.yards) yd away")
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundStyle(W_FAIRWAY2)
                                        }
                                        Spacer()
                                        Image(systemName: "flag.fill")
                                            .font(.system(size: 9))
                                            .foregroundStyle(W_FAIRWAY)
                                    }
                                    .padding(7)
                                    .background(W_FAINT)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 4)
                            }
                        }
                    }

                case .empty:
                    Spacer()
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 22)).foregroundStyle(W_DIM)
                    Text("No courses nearby")
                        .font(.system(size: 11)).foregroundStyle(W_DIM)
                    Text("Start from iPhone")
                        .font(.system(size: 9)).foregroundStyle(W_DIM)
                    Spacer()
                    Button("Retry") { phase = .searching }
                        .font(.system(size: 11)).foregroundStyle(W_FAIRWAY2)
                        .buttonStyle(.plain).padding(.bottom, 6)

                case .sent:
                    Spacer()
                    ProgressView().tint(W_FAIRWAY2)
                    Text("Starting round…")
                        .font(.system(size: 11)).foregroundStyle(W_INK).padding(.top, 4)
                    Text("Check iPhone")
                        .font(.system(size: 9)).foregroundStyle(W_DIM)
                    Spacer()
                }

                if phoneError {
                    Text("iPhone not reachable")
                        .font(.system(size: 9)).foregroundStyle(W_PIN)
                        .padding(.bottom, 4)
                }
            }
        }
        .task { await search() }
        .onChange(of: phase) { _, _ in phoneError = false }
    }

    private func tapped(_ item: Nearby) {
        guard connectivity.isPhoneReachable else { phoneError = true; return }
        connectivity.sendStartRound(courseName: item.name,
                                    lat: item.coordinate.latitude,
                                    lon: item.coordinate.longitude)
        phase = .sent
    }

    private func search() async {
        var waited = 0
        while location.location == nil && waited < 16 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            waited += 1
        }
        guard let loc = location.location else { phase = .empty; return }

        let req = MKLocalPointsOfInterestRequest(center: loc.coordinate, radius: 1500)
        req.pointOfInterestFilter = MKPointOfInterestFilter(including: [.golf])
        guard let items = try? await MKLocalSearch(request: req).start().mapItems,
              !items.isEmpty else { phase = .empty; return }

        let results = items.compactMap { item -> Nearby? in
            guard let name = item.name else { return nil }
            let coord = item.placemark.coordinate
            let dist = loc.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            return Nearby(name: name, coordinate: coord, yards: Int(dist * 1.09361))
        }.sorted { $0.yards < $1.yards }

        phase = results.isEmpty ? .empty : .found(results)
    }
}

// MARK: - Active hole: Topo hero + swipeable map

struct ActiveHoleWatchView: View {
    @Bindable var connectivity: WatchConnectivityManager
    let location: WatchLocationManager

    @State private var showScore = false
    @State private var voice = WatchVoiceManager()

    private var liveYards: Int? {
        guard connectivity.hasPinCoordinates,
              let d = location.distanceInYards(toLat: connectivity.pinLat, lon: connectivity.pinLon)
        else { return nil }
        return Int(d.rounded())
    }
    private var displayYards: Int { liveYards ?? connectivity.yardage }
    private var frontYards: Int { max(0, displayYards - 15) }
    private var backYards:  Int { displayYards + 15 }

    var body: some View {
        ZStack {
            if showScore {
                ScoreInputView(connectivity: connectivity) {
                    showScore = false
                    connectivity.sendNextHole()
                } onCancel: {
                    showScore = false
                }
            } else {
                TabView {
                    topoHeroView
                        .tag(0)
                    WatchHoleMapView(connectivity: connectivity)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .background(Color.black.ignoresSafeArea())
            }

            voiceOverlay
        }
        .animation(.easeInOut(duration: 0.18), value: voice.state)
    }

    @ViewBuilder
    private var voiceOverlay: some View {
        switch voice.state {
        case .textInput:
            WatchTextInputView { text in
                voice.submitText(text, par: connectivity.par, onCommand: handleVoiceCommand)
            } onCancel: {
                voice.cancelListening()
            }
        case .confirmed(let score, let word, let delta):
            VoiceConfirmedOverlay(score: score, word: word, delta: delta)
        case .showingStatus:
            VoiceStatusOverlay(connectivity: connectivity)
        case .disambiguate(let heard, let options):
            VoiceDisambiguateOverlay(heard: heard, options: options) { idx in
                voice.selectDisambiguation(index: idx, par: connectivity.par,
                                           onCommand: handleVoiceCommand)
            }
        case .idle:
            EmptyView()
        }
    }

    private func handleVoiceCommand(_ cmd: GolfVoiceCommand) {
        switch cmd {
        case .score(let s):
            connectivity.sendScoreUpdate(hole: connectivity.currentHole,
                                         strokes: s, putts: 0, fairwayHit: nil)
        case .nextHole:
            connectivity.sendNextHole()
        case .endRound:
            connectivity.sendEndRound()
        case .markPin, .queryStatus, .unrecognized:
            break
        }
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
                    .font(.system(size: 60, weight: .semibold).monospacedDigit())
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
                    let radii: [CGFloat] = [14, 24, 36, 48, 60]
                    for (i, r) in radii.enumerated() {
                        var p = Path()
                        p.addEllipse(in: CGRect(x: cx - r * 1.6, y: cy - r * 0.8,
                                                width: r * 3.2, height: r * 1.6))
                        ctx.stroke(p, with: .color(W_FAIRWAY.opacity(0.35 - Double(i) * 0.05)), lineWidth: 0.7)
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
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - 2.5, y: cy - 2.5, width: 5, height: 5)),
                             with: .color(W_PIN))
                }
                .frame(maxWidth: .infinity).frame(height: 48)

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("F").font(.system(size: 9, design: .monospaced)).foregroundStyle(W_DIM)
                        Text("\(frontYards)").font(.system(size: 26, weight: .semibold).monospacedDigit()).foregroundStyle(W_FAIRWAY2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("B").font(.system(size: 9, design: .monospaced)).foregroundStyle(W_DIM)
                        Text("\(backYards)").font(.system(size: 26, weight: .semibold).monospacedDigit()).foregroundStyle(W_FAIRWAY2)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 2)

                // Mic button
                Button {
                    voice.startListening()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 10))
                        Text("Speak Score")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 5)
                    .background(W_FAINT)
                    .foregroundStyle(W_FAIRWAY2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8).padding(.top, 4)

                Button { showScore = true } label: {
                    Text("Record Score")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 7)
                        .background(W_FAIRWAY).foregroundStyle(W_INK)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8).padding(.top, 3).padding(.bottom, 4)
            }
        }
    }
}

// MARK: - Voice overlays

private struct WatchTextInputView: View {
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(W_FAIRWAY2)

                TextField("Say a score…", text: $text)
                    .focused($focused)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        let t = text; text = ""
                        onSubmit(t)
                    }

                Button("Cancel", action: onCancel)
                    .font(.system(size: 11)).foregroundStyle(W_DIM)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
        }
        .onAppear { focused = true }
    }
}

private struct VoiceConfirmedOverlay: View {
    let score: Int
    let word: String
    let delta: Int

    private var scoreColor: Color {
        delta < 0 ? W_FAIRWAY2 : delta == 0 ? W_INK : W_PIN
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 64, weight: .bold).monospacedDigit())
                    .foregroundStyle(scoreColor)
                Text(word)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(scoreColor)
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(W_FAIRWAY2)
                    Text("SAVED")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(W_FAIRWAY2)
                        .tracking(1.5)
                }
                .padding(.top, 6)
            }
        }
    }
}

private struct VoiceStatusOverlay: View {
    let connectivity: WatchConnectivityManager

    private var holesPlayed: Int { connectivity.scores.keys.count }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 4) {
                Text("THRU \(holesPlayed)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(W_DIM).tracking(1.5)
                Text("\(connectivity.totalStrokes)")
                    .font(.system(size: 52, weight: .semibold).monospacedDigit())
                    .foregroundStyle(W_INK)
                Text("STROKES")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(W_DIM).tracking(1.5)
                Text("HOLE \(connectivity.currentHole)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(W_FAIRWAY2)
                    .padding(.top, 4)
            }
        }
    }
}

private struct VoiceDisambiguateOverlay: View {
    let heard: String
    let options: [String]
    let onSelect: (Int) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 5) {
                Text("HEARD: \"\(heard.prefix(18))\"")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(W_DIM).tracking(0.6)
                    .lineLimit(1)
                    .padding(.bottom, 2)

                ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                    Button { onSelect(idx) } label: {
                        Text(opt)
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity).padding(.vertical, 5)
                            .background(W_FAINT)
                            .foregroundStyle(W_INK)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
            }
        }
    }
}

// MARK: - Watch map page

struct WatchHoleMapView: View {
    let connectivity: WatchConnectivityManager

    @State private var position: MapCameraPosition = .automatic
    @State private var hazards: [WatchHazard] = []
    @State private var hazardTask: Task<Void, Never>?

    private var pinCoord: CLLocationCoordinate2D? {
        guard connectivity.hasPinCoordinates else { return nil }
        return CLLocationCoordinate2D(latitude: connectivity.pinLat, longitude: connectivity.pinLon)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let pin = pinCoord {
                Map(position: $position) {
                    ForEach(hazards) { h in
                        MapPolygon(coordinates: h.coordinates)
                            .foregroundStyle(h.isWater ?
                                Color(red: 0.42, green: 0.55, blue: 0.63).opacity(0.55) :
                                Color(red: 0.85, green: 0.75, blue: 0.54).opacity(0.6))
                            .stroke(h.isWater ?
                                Color(red: 0.42, green: 0.55, blue: 0.63) :
                                Color(red: 0.72, green: 0.61, blue: 0.40),
                                lineWidth: 1)
                    }
                    Annotation("", coordinate: pin, anchor: .bottom) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(W_PIN, in: Circle())
                    }
                    UserAnnotation()
                }
                .mapStyle(.hybrid(elevation: .flat))
                .onAppear { centerOn(pin); loadHazards(pin) }
                .onChange(of: connectivity.currentHole) { _, _ in
                    if let p = pinCoord { centerOn(p); hazards = []; loadHazards(p) }
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "map.slash")
                        .font(.system(size: 28)).foregroundStyle(W_DIM)
                    Text("No map data")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(W_INK)
                    Text("GPS not set for\nthis hole")
                        .font(.system(size: 10)).foregroundStyle(W_DIM)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private func centerOn(_ pin: CLLocationCoordinate2D) {
        position = .region(MKCoordinateRegion(
            center: pin,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        ))
    }

    private func loadHazards(_ pin: CLLocationCoordinate2D) {
        hazardTask?.cancel()
        hazardTask = Task {
            guard let loaded = try? await WatchHazardLoader.fetch(near: pin) else { return }
            if !Task.isCancelled { hazards = loaded }
        }
    }
}

// Lightweight hazard types local to the watch target
private struct WatchHazard: Identifiable {
    let id = UUID()
    let isWater: Bool
    let coordinates: [CLLocationCoordinate2D]
}

private struct WatchHazardLoader {
    static func fetch(near center: CLLocationCoordinate2D) async throws -> [WatchHazard] {
        let pad = 0.0022
        let s = center.latitude  - pad,  n = center.latitude  + pad
        let w = center.longitude - pad * 1.5, e = center.longitude + pad * 1.5

        let query = """
        [out:json][timeout:25];
        (
          way["golf"="bunker"](\(s),\(w),\(n),\(e));
          way["golf"="water_hazard"](\(s),\(w),\(n),\(e));
          way["natural"="water"](\(s),\(w),\(n),\(e));
        );
        out body;
        >;
        out skel qt;
        """
        var req = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var comps = URLComponents()
        comps.queryItems = [URLQueryItem(name: "data", value: query)]
        req.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        req.timeoutInterval = 30

        let (data, _) = try await URLSession.shared.data(for: req)

        struct Resp: Decodable { let elements: [El] }
        struct El: Decodable {
            let type: String; let id: Int
            let lat: Double?; let lon: Double?
            let nodes: [Int]?; let tags: [String: String]?
        }
        let resp = try JSONDecoder().decode(Resp.self, from: data)

        var nodeLookup: [Int: CLLocationCoordinate2D] = [:]
        for el in resp.elements where el.type == "node" {
            if let lat = el.lat, let lon = el.lon {
                nodeLookup[el.id] = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }

        var result: [WatchHazard] = []
        for el in resp.elements where el.type == "way" {
            guard let tags = el.tags, let nodeIds = el.nodes else { continue }
            let coords = nodeIds.compactMap { nodeLookup[$0] }
            guard coords.count >= 3 else { continue }
            let isWater = tags["golf"] == "water_hazard" || tags["natural"] == "water"
            let isBunker = tags["golf"] == "bunker"
            if isWater || isBunker { result.append(WatchHazard(isWater: isWater, coordinates: coords)) }
        }
        return result
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
                            fairwayToggle(label: "Hit",  value: true,  selected: fairway == true,  accent: W_FAIRWAY)
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
            fairway = selected ? nil : value
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
