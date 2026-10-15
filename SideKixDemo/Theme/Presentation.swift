import SwiftUI

/// How domain values look. The domain types stay free of SwiftUI so they can be reused
/// (widgets, command-line tools, a server) without pulling in the UI framework.
extension Accent {
    var color: Color {
        switch self {
        case .gold: SX.gold
        case .coral: SX.coral
        case .teal: SX.teal
        case .sky: SX.sky
        case .violet: SX.violet
        }
    }
}

extension Offer {
    var symbol: String {
        switch self {
        case .sessions: "video.fill"
        case .content: "text.book.closed.fill"
        case .events: "calendar"
        }
    }

    var blurb: String {
        switch self {
        case .sessions: "1:1 sessions"
        case .content: "Guides & playbooks"
        case .events: "Live events"
        }
    }
}
