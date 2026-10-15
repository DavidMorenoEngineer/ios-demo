import Foundation

enum Offer: String, CaseIterable, Hashable, Sendable {
    case sessions = "Sessions"
    case content = "Content"
    case events = "Events"
}

enum Accent: String, Hashable, Sendable {
    case gold, coral, teal, sky, violet
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
