import SwiftUI

/// Design tokens read from the public SideKix site: a warm near-black canvas,
/// gold accents and a muted parchment text scale. Same values as the Flutter demo.
enum SX {
    static let bgDeep = Color(hex: 0x060502)
    static let bg = Color(hex: 0x0E0C09)
    static let surface = Color(hex: 0x17150E)
    static let surfaceHigh = Color(hex: 0x26241F)
    static let line = Color(hex: 0x3C3A35)

    static let gold = Color(hex: 0xD4A856)
    static let goldLight = Color(hex: 0xF3E4A8)
    static let goldBright = Color(hex: 0xFFD166)
    static let goldInk = Color(hex: 0x1B1400)

    static let text = Color(hex: 0xDDD8CA)
    static let textSoft = Color(hex: 0xCEC9BC)
    static let muted = Color(hex: 0xB7AF9E)
    static let dim = Color(hex: 0x877F6F)

    static let coral = Color(hex: 0xFF6367)
    static let teal = Color(hex: 0x5FB6A6)
    static let sky = Color(hex: 0x6FB0E0)
    static let violet = Color(hex: 0xB18BE4)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Serif display (the site uses Cormorant Garamond) maps to New York on iOS;
/// body copy and labels use the system face. All styles scale with Dynamic Type.
extension Font {
    static func sxDisplay(_ style: TextStyle, weight: Weight = .semibold) -> Font {
        .system(style, design: .serif, weight: weight)
    }
    static func sxBody(_ style: TextStyle = .subheadline, weight: Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }
    static let sxLabel = Font.system(.caption2, design: .rounded, weight: .semibold)
}

extension View {
    /// Small uppercase tracked label ("IN YOUR CORNER").
    func sxLabelStyle(_ color: Color = SX.gold) -> some View {
        font(.sxLabel).tracking(1.6).textCase(.uppercase).foregroundStyle(color)
    }
}

extension EnvironmentValues {
    /// Set by the root view; lets leaf views pick roomier typography on iPad
    /// without each re-reading the size class.
    @Entry var isRegularWidth: Bool = false
}
