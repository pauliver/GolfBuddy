import Foundation
import Speech
import AVFoundation

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

@Observable
class WatchVoiceManager {

    enum ListenState: Equatable {
        case idle
        case listening(partial: String)
        case confirmed(score: Int, word: String, delta: Int)
        case showingStatus
        case disambiguate(heard: String, options: [String])

        static func == (lhs: ListenState, rhs: ListenState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.showingStatus, .showingStatus): return true
            case (.listening(let a), .listening(let b)): return a == b
            case (.confirmed(let a, let b, let c), .confirmed(let d, let e, let f)):
                return a == d && b == e && c == f
            case (.disambiguate(let a, _), .disambiguate(let b, _)): return a == b
            default: return false
            }
        }
    }

    var state: ListenState = .idle
    var isAvailable: Bool = false

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()
    private var autoStopWork: DispatchWorkItem?

    // MARK: - Authorization

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAvailable = status == .authorized
            }
        }
    }

    // MARK: - Listen

    func startListening(par: Int, onCommand: @escaping (GolfVoiceCommand) -> Void) {
        guard isAvailable, !engine.isRunning else { return }

        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let req = request else { return }
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = false

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }
            engine.prepare()
            try engine.start()
        } catch {
            state = .idle
            return
        }

        state = .listening(partial: "")

        task = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    if result.isFinal {
                        self.stopAudio()
                        self.resolve(text: text, par: par, onCommand: onCommand)
                    } else {
                        self.state = .listening(partial: text)
                    }
                }
            } else if error != nil {
                self.stopAudio()
                DispatchQueue.main.async { self.state = .idle }
            }
        }

        // Auto-stop after 6 s
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if case .listening(let partial) = self.state {
                self.stopAudio()
                if partial.isEmpty {
                    self.state = .idle
                } else {
                    self.resolve(text: partial, par: par, onCommand: onCommand)
                }
            }
        }
        autoStopWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: work)
    }

    func cancelListening() {
        autoStopWork?.cancel()
        stopAudio()
        state = .idle
    }

    private func stopAudio() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }

    // MARK: - Resolve a transcription to a command + state

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

    func selectDisambiguation(index: Int, par: Int, onCommand: @escaping (GolfVoiceCommand) -> Void) {
        guard case .disambiguate(_, let options) = state else { return }
        let opt = options[index]
        // Parse the label back to strokes
        if let n = opt.first.flatMap({ Int(String($0)) }) {
            let cmd = GolfVoiceCommand.score(strokes: n)
            let delta = n - par
            state = .confirmed(score: n, word: scoreWord(delta), delta: delta)
            onCommand(cmd)
            dismiss(after: 2.5)
        } else if opt.contains("again") {
            state = .idle
        } else {
            state = .idle
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

        // End round
        if lower.contains("end round") || lower.contains("finish round") ||
           (lower.contains("done") && lower.count < 20) { return .endRound }

        // Status
        if lower.contains("how am i") || lower.contains("how am i doing") ||
           (lower.contains("how") && lower.contains("doing")) ||
           lower.contains("score so far") || lower.contains("what's my score") { return .queryStatus }

        // Mark pin
        if (lower.contains("mark") && lower.contains("pin")) ||
           lower.contains("mark the pin") { return .markPin }

        // Next hole
        if lower.contains("next hole") || lower == "next" { return .nextHole }

        // Score words relative to par
        if lower.contains("hole in one") || lower == "ace" { return .score(strokes: 1) }
        if lower.contains("eagle") && !lower.contains("double eagle") { return .score(strokes: max(1, par - 2)) }
        if lower.contains("double eagle") || lower.contains("albatross") { return .score(strokes: max(1, par - 3)) }
        if lower.contains("birdie") { return .score(strokes: max(1, par - 1)) }
        if lower == "par" || lower == "made par" || lower.contains("hit par") { return .score(strokes: par) }
        if lower.contains("double bogey") || (lower.contains("double") && !lower.contains("bogey") == false) {
            return .score(strokes: par + 2)
        }
        if lower.contains("triple bogey") || lower.contains("triple") { return .score(strokes: par + 3) }
        if lower.contains("bogey") { return .score(strokes: par + 1) }

        // Number words (check "four" before bare digit to catch "fore" homophone)
        let wordMap: [(String, Int)] = [
            ("one", 1), ("two", 2), ("three", 3), ("four", 4), ("five", 5),
            ("six", 6), ("seven", 7), ("eight", 8), ("nine", 9), ("ten", 10),
        ]
        // "four" vs "fore" — ambiguous, fall through to disambiguation
        if lower.contains("fore") && !lower.contains("before") && !lower.contains("therefore") {
            return .unrecognized(lower)
        }
        for (word, n) in wordMap where lower.contains(word) { return .score(strokes: n) }

        // Digit scan
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
