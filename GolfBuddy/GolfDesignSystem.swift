import SwiftUI

// MARK: - Design tokens matching the "calm outdoors" palette from the design prototype

extension Color {
    static let golfPaper   = Color(golfHex: "F2ECDD")
    static let golfPaper2  = Color(golfHex: "E6DDC6")
    static let golfPaper3  = Color(golfHex: "D9CDB0")
    static let golfInk     = Color(golfHex: "1A2218")
    static let golfInkSoft = Color(golfHex: "4A5346")
    static let golfInkMute = Color(golfHex: "7A8472")
    static let golfMoss    = Color(golfHex: "3D5A3B")
    static let golfFairway = Color(golfHex: "6B8E5A")
    static let golfFairway2 = Color(golfHex: "94B27E")
    static let golfSand    = Color(golfHex: "D9C08A")
    static let golfPin     = Color(golfHex: "B8463A")

    init(golfHex hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Font helpers

extension Font {
    /// Instrument Serif substitute — Georgia is always available on iOS
    static func golfSerif(size: CGFloat, italic: Bool = false) -> Font {
        italic
            ? Font.custom("Georgia-Italic", size: size)
            : Font.custom("Georgia", size: size)
    }

    /// Geist Mono substitute — system monospaced
    static func golfMono(size: CGFloat, weight: Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Score word helpers

func scoreWord(_ diff: Int, short: Bool = false) -> String {
    switch diff {
    case ..<(-2): return short ? "Albatross" : "Albatross or better"
    case -2:      return "Eagle"
    case -1:      return "Birdie"
    case  0:      return "Par"
    case  1:      return "Bogey"
    case  2:      return "Double bogey"
    default:      return "+\(diff)"
    }
}

func scoreColor(_ diff: Int) -> Color {
    switch diff {
    case ..<0: return .golfFairway2
    case    0: return .golfInk
    case    1: return .golfInkSoft
    default:   return .golfPin
    }
}
