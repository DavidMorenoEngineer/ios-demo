import SwiftUI

enum Offer: String, CaseIterable, Hashable, Sendable {
    case sessions = "Sessions"
    case content = "Content"
    case events = "Events"

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

enum Accent: String, Hashable, Sendable {
    case gold, coral, teal, sky, violet

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

struct Advisor: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let title: String
    let level: Int
    let why: String
    let skills: [String]
    let style: String
    let offers: [Offer]
    let accent: Accent

    var initials: String { name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined() }
    var levelLabel: String { "Level \(level)" }
    var firstName: String { String(name.split(separator: " ").first ?? "") }

    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }
        return ([name, title, why, style] + skills).contains { $0.localizedCaseInsensitiveContains(q) }
    }
}
