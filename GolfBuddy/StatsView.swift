import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var rounds: [GolfRound]

    private var recentRounds: [GolfRound] { Array(rounds.prefix(10)) }
    private var chartRounds:  [GolfRound] { Array(recentRounds.reversed()) }

    var body: some View {
        Group {
            if rounds.isEmpty {
                ContentUnavailableView("No Stats Yet", systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Complete a round to see your stats."))
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        trendChart
                        metricsGrid
                        if rounds.count > 1 { courseBreakdown }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color.golfPaper.ignoresSafeArea())
    }

    // MARK: - Scoring trend

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SCORING TREND")
                .font(.golfMono(size: 10))
                .foregroundStyle(Color.golfInkMute)
                .tracking(1.5)

            Chart(Array(chartRounds.enumerated()), id: \.element.id) { i, round in
                LineMark(
                    x: .value("Round", i),
                    y: .value("Score", round.totalStrokes)
                )
                .foregroundStyle(Color.golfMoss)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Round", i),
                    y: .value("Score", round.totalStrokes)
                )
                .foregroundStyle(
                    LinearGradient(colors: [Color.golfMoss.opacity(0.25), Color.golfMoss.opacity(0.02)],
                                   startPoint: .top, endPoint: .bottom)
                )

                PointMark(
                    x: .value("Round", i),
                    y: .value("Score", round.totalStrokes)
                )
                .foregroundStyle(Color.golfMoss)
                .symbolSize(30)

                // Par reference line
                if let par = round.course?.totalPar, par > 0 {
                    RuleMark(y: .value("Par", par))
                        .foregroundStyle(Color.golfInkMute.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let i = value.as(Int.self), i < chartRounds.count {
                        AxisValueLabel {
                            Text(chartRounds[i].date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.golfMono(size: 9))
                                .foregroundStyle(Color.golfInkMute)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color.golfInk.opacity(0.06))
                    AxisValueLabel()
                        .font(.golfMono(size: 9))
                        .foregroundStyle(Color.golfInkMute)
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(Color.golfPaper2, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Key metrics grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            StatCard(title: "Avg Score",   value: avgScore,    sub: "per round")
            StatCard(title: "vs Par",      value: avgVsPar,    sub: "average")
            StatCard(title: "Fairways",    value: fairwayPct,  sub: "hit %")
            StatCard(title: "GIR",         value: girPct,      sub: "greens in reg.")
            StatCard(title: "Avg Putts",   value: avgPutts,    sub: "per round")
            StatCard(title: "Best Round",  value: bestRound,   sub: bestRoundCourse)
        }
    }

    // MARK: - Per-course breakdown

    private var courseBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BY COURSE")
                .font(.golfMono(size: 10))
                .foregroundStyle(Color.golfInkMute)
                .tracking(1.5)

            ForEach(courseGroups, id: \.name) { group in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.name).font(.headline).foregroundStyle(Color.golfInk)
                        Text("\(group.rounds) rounds").font(.caption).foregroundStyle(Color.golfInkMute)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(group.avgScore).font(.system(size: 20, weight: .bold).monospacedDigit())
                            .foregroundStyle(Color.golfInk)
                        let diff = group.avgDiff
                        Text(diff == 0 ? "E" : (diff > 0 ? "+\(diff)" : "\(diff)"))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(diff <= 0 ? Color.golfMoss : Color.golfPin)
                    }
                }
                .padding(12)
                .background(Color.golfPaper2, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Computed stats

    private var avgScore: String {
        let scores = rounds.map(\.totalStrokes).filter { $0 > 0 }
        guard !scores.isEmpty else { return "—" }
        return String(format: "%.1f", Double(scores.reduce(0, +)) / Double(scores.count))
    }

    private var avgVsPar: String {
        let diffs = rounds.compactMap { r -> Int? in
            guard let par = r.course?.totalPar, par > 0, r.totalStrokes > 0 else { return nil }
            return r.totalStrokes - par
        }
        guard !diffs.isEmpty else { return "—" }
        let avg = Double(diffs.reduce(0, +)) / Double(diffs.count)
        let rounded = Int(avg.rounded())
        return rounded == 0 ? "E" : (rounded > 0 ? "+\(rounded)" : "\(rounded)")
    }

    private var fairwayPct: String {
        let hit = rounds.reduce(0) { $0 + $1.fairwaysHit }
        let elig = rounds.reduce(0) { $0 + $1.fairwaysEligible }
        guard elig > 0 else { return "—" }
        return "\(Int((Double(hit) / Double(elig) * 100).rounded()))%"
    }

    private var girPct: String {
        let gir  = rounds.reduce(0) { $0 + $1.greensInRegulation() }
        let elig = rounds.reduce(0) { $0 + $1.holesEligibleForGIR() }
        guard elig > 0 else { return "—" }
        return "\(Int((Double(gir) / Double(elig) * 100).rounded()))%"
    }

    private var avgPutts: String {
        let putts = rounds.map(\.totalPutts).filter { $0 > 0 }
        guard !putts.isEmpty else { return "—" }
        return String(format: "%.1f", Double(putts.reduce(0, +)) / Double(putts.count))
    }

    private var bestRound: String {
        guard let best = rounds.min(by: { $0.scoreVsPar < $1.scoreVsPar }) else { return "—" }
        let d = best.scoreVsPar
        return d == 0 ? "E" : (d > 0 ? "+\(d)" : "\(d)")
    }

    private var bestRoundCourse: String {
        rounds.min(by: { $0.scoreVsPar < $1.scoreVsPar })?.course?.name ?? ""
    }

    private struct CourseGroup {
        let name: String
        let rounds: Int
        let avgScore: String
        let avgDiff: Int
    }

    private var courseGroups: [CourseGroup] {
        let grouped = Dictionary(grouping: rounds) { $0.course?.name ?? "Unknown" }
        return grouped.map { name, rs in
            let scores = rs.map(\.totalStrokes).filter { $0 > 0 }
            let avg = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
            let diffs = rs.compactMap { r -> Int? in
                guard let par = r.course?.totalPar, par > 0 else { return nil }
                return r.totalStrokes - par
            }
            let avgDiff = diffs.isEmpty ? 0 : diffs.reduce(0, +) / diffs.count
            return CourseGroup(
                name: name, rounds: rs.count,
                avgScore: avg > 0 ? "\(avg)" : "—",
                avgDiff: avgDiff
            )
        }.sorted { $0.rounds > $1.rounds }
    }
}

// MARK: - Stat card

struct StatCard: View {
    let title: String
    let value: String
    let sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.golfMono(size: 9))
                .foregroundStyle(Color.golfInkMute)
                .tracking(1.2)
            Text(value)
                .font(.system(size: 28, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.golfInk)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(sub)
                .font(.caption)
                .foregroundStyle(Color.golfInkMute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.golfPaper2, in: RoundedRectangle(cornerRadius: 14))
    }
}
