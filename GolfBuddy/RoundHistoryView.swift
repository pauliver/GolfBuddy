import SwiftUI
import SwiftData

struct RoundHistoryView: View {
    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var completedRounds: [GolfRound]

    @State private var tab: Tab = .rounds

    enum Tab { case rounds, stats }

    var body: some View {
        NavigationStack {
            Group {
                switch tab {
                case .rounds: roundsList
                case .stats:  StatsView()
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View", selection: $tab) {
                        Text("Rounds").tag(Tab.rounds)
                        Text("Stats").tag(Tab.stats)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
        }
    }

    private var roundsList: some View {
        List {
            ForEach(completedRounds) { round in
                NavigationLink(destination: RoundDetailView(round: round)) {
                    RoundRowView(round: round)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.golfPaper.ignoresSafeArea())
        .overlay {
            if completedRounds.isEmpty {
                ContentUnavailableView("No Rounds Yet", systemImage: "chart.bar",
                    description: Text("Complete a round to see your history."))
            }
        }
    }
}

// MARK: - Row

struct RoundRowView: View {
    let round: GolfRound

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(round.course?.name ?? "Unknown Course")
                    .font(.headline).foregroundStyle(Color.golfInk)
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(Color.golfInkMute)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(round.totalStrokes)")
                    .font(.title3.monospacedDigit()).fontWeight(.bold)
                    .foregroundStyle(Color.golfInk)
                if let par = round.course?.totalPar, par > 0 {
                    let diff = round.scoreVsPar
                    Text(diff == 0 ? "E" : (diff > 0 ? "+\(diff)" : "\(diff)"))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(diff <= 0 ? Color.golfFairway : Color.golfPin)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Round detail

struct RoundDetailView: View {
    let round: GolfRound

    var body: some View {
        List {
            Section {
                statRow("Total Strokes", value: "\(round.totalStrokes)")
                if let par = round.course?.totalPar, par > 0 {
                    let diff = round.scoreVsPar
                    HStack {
                        Text("vs. Par")
                        Spacer()
                        Text(diff == 0 ? "Even" : (diff > 0 ? "+\(diff)" : "\(diff)"))
                            .fontWeight(.semibold)
                            .foregroundStyle(diff <= 0 ? Color.golfFairway : Color.golfPin)
                    }
                }
                statRow("Date", value: round.date.formatted(date: .long, time: .omitted))
                if round.totalPutts > 0 { statRow("Putts", value: "\(round.totalPutts)") }
                if round.fairwaysEligible > 0 {
                    statRow("Fairways", value: "\(round.fairwaysHit) / \(round.fairwaysEligible)")
                }
                let gir = round.greensInRegulation()
                let holes = round.holesEligibleForGIR()
                if holes > 0 { statRow("GIR", value: "\(gir) / \(holes)") }
            }

            Section("Scorecard") {
                ForEach(round.scores.sorted { $0.holeNumber < $1.holeNumber }) { score in
                    let hole = round.course?.sortedHoles.first { $0.number == score.holeNumber }
                    HStack(spacing: 6) {
                        Text("H\(score.holeNumber)")
                            .font(.golfMono(size: 13, weight: .medium))
                            .foregroundStyle(Color.golfInkSoft)
                            .frame(width: 30, alignment: .leading)
                        if let h = hole {
                            Text("p\(h.par)")
                                .font(.golfMono(size: 10))
                                .foregroundStyle(Color.golfInkMute)
                        }
                        Spacer()
                        // Fairway indicator
                        if let fw = score.fairwayHit {
                            Image(systemName: fw ? "checkmark" : "xmark")
                                .font(.caption2)
                                .foregroundStyle(fw ? Color.golfFairway : Color.golfPin)
                        }
                        // Putts
                        if score.putts > 0 {
                            Text("\(score.putts)p")
                                .font(.golfMono(size: 11))
                                .foregroundStyle(Color.golfInkMute)
                        }
                        // Strokes + diff
                        Text("\(score.strokes)")
                            .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        if let h = hole {
                            let diff = score.strokes - h.par
                            Text(diff == 0 ? "E" : (diff > 0 ? "+\(diff)" : "\(diff)"))
                                .font(.golfMono(size: 11))
                                .foregroundStyle(diff < 0 ? Color.golfFairway2 : diff == 0 ? Color.golfInkSoft : Color.golfPin)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.golfPaper.ignoresSafeArea())
        .navigationTitle(round.course?.name ?? "Round")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(Color.golfInkSoft)
        }
    }
}
