import Foundation
import SwiftUI

// MARK: - Command output

enum GolfVoiceCommand {
    case score(strokes: Int)
    case nextHole
    case queryStatus
    case markPin
    case endRound
    case unrecognized(String)
}

// MARK: - Observable voice manager
// Uses watchOS native text/dictation input — no Speech framework required.

@Observable
class WatchVoiceManager {

    enum ListenState: Equatable {
        case idle
        case textInput                                        // system dictation sheet is active
        case confirmed(score: Int, word: String, delta: Int)
        case showingStatus
        case disambiguate(heard: String, options: [String])

        static func == (lhs: ListenState, rhs: ListenState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.textInput, .textInput), (.showingStatus, .showingStatus):
                return true
            case (.confirmed(let a, let b, let c), .confirmed(let d, let e, let f)):
                return a == d && b == e && c == f
            case (.disambiguate(let a, _), .disambiguate(let b, _)):
                return a == b
            default:
                return false
            }
        }
    }

    var state: ListenState = .idle
    // Always available — dictation is built into watchOS
    var isAvailable: Bool = true

    // MARK: - Start / cancel

    func startListening() {
        state = .textInput
    }

    func cancelListening() {
        state = .idle
    }

    // MARK: - Called when user submits text from the dictation sheet

    func submitText(_ text: String, par: Int, onCommand: @escaping (GolfVoiceCommand) -> Void) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { state = .idle; return }
        resolve(text: trimmed, par: par, onCommand: onCommand)
    }

    func selectDisambiguation(index: Int, par: Int, onCommand: @escaping (GolfVoiceCommand) -> Void) {
        guard case .disambiguate(_, let options) = state else { return }
        let opt = options[index]
        if let n = opt.first.flatMap({ Int(String($0)) }) {
            let delta = n - par
            state = .confirmed(score: n, word: scoreWord(delta), delta: delta)
            onCommand(.score(strokes: n))
            dismiss(after: 2.5)
        } else {
            state = .idle
        }
    }

    // MARK: - Resolve transcription → command + state

    private func resolve(text: String, par: Int, onCommand: @escaping (GolfVoiceCommand) -> Void) {
        let cmd = parse(text, par: par)
        switch cmd {
        case .score(let strokes):
            let delta = strokes - par
            state = .confirmed(score: strokes, word: scoreWord(delta), delta: delta)
            onCommand(cmd)
            dismiss(after: 2.5)
        case .queryStatus:
            state = .showingStatus
            onCommand(cmd)
            dismiss(after: 4.0)
        case .unrecognized(let heard):
            state = .disambiguate(heard: heard, options: buildOptions(from: heard, par: par))
        default:
            state = .idle
            onCommand(cmd)
        }
    }

    private func dismiss(after seconds: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let self else { return }
            switch self.state {
            case .confirmed, .showingStatus: self.state = .idle
            default: break
            }
        }
    }

    // MARK: - Parser

    func parse(_ text: String, par: Int) -> GolfVoiceCommand {
        let lower = text.lowercased().trimmingCharacters(in: .whitespaces)

        if lower.contains("end round") || lower.contains("finish round") ||
           (lower.contains("done") && lower.count < 20) { return .endRound }

        if lower.contains("how am i") || (lower.contains("how") && lower.contains("doing")) ||
           lower.contains("score so far") || lower.contains("what's my score") { return .queryStatus }

        if (lower.contains("mark") && lower.contains("pin")) ||
           lower.contains("mark the pin") { return .markPin }

        if lower.contains("next hole") || lower == "next" { return .nextHole }

        if lower.contains("hole in one") || lower == "ace" { return .score(strokes: 1) }
        if lower.contains("double eagle") || lower.contains("albatross") { return .score(strokes: max(1, par - 3)) }
        if lower.contains("eagle") { return .score(strokes: max(1, par - 2)) }
        if lower.contains("birdie") { return .score(strokes: max(1, par - 1)) }
        if lower == "par" || lower == "made par" || lower.contains("hit par") { return .score(strokes: par) }
        if lower.contains("triple bogey") || lower.contains("triple") { return .score(strokes: par + 3) }
        if lower.contains("double bogey") || (lower.contains("double") && lower.contains("bogey")) {
            return .score(strokes: par + 2)
        }
        if lower.contains("bogey") { return .score(strokes: par + 1) }

        // "four" vs "fore" ambiguity
        if lower.contains("fore") && !lower.contains("before") && !lower.contains("therefore") {
            return .unrecognized(lower)
        }

        let wordMap: [(String, Int)] = [
            ("one", 1), ("two", 2), ("three", 3), ("four", 4), ("five", 5),
            ("six", 6), ("seven", 7), ("eight", 8), ("nine", 9), ("ten", 10),
        ]
        for (word, n) in wordMap where lower.contains(word) { return .score(strokes: n) }

        for token in lower.components(separatedBy: .whitespaces) {
            if let n = Int(token), n >= 1, n <= 15 { return .score(strokes: n) }
        }

        return .unrecognized(lower)
    }

    private func buildOptions(from heard: String, par: Int) -> [String] {
        var opts: [String] = []
        if heard.contains("fore") || heard.contains("for ") {
            opts.append("\(par) strokes · Par")
            opts.append("4 strokes")
        }
        if heard.contains("tree") || heard.contains("free") { opts.append("3 strokes") }
        if opts.isEmpty { opts.append("Skip this hole") }
        opts.append("Try again")
        return opts
    }

    func scoreWord(_ delta: Int) -> String {
        switch delta {
        case ..<(-1): return "Eagle"
        case -1:      return "Birdie"
        case  0:      return "Par"
        case  1:      return "Bogey"
        case  2:      return "Double"
        default:      return "+\(delta)"
        }
    }
}
