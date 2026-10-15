import ComposableArchitecture
import Foundation

/// Fetches advisors. All demo content lives here, behind the client, so the
/// reducers never know whether data is local or remote: swap `liveValue` for a
/// URLSession-backed implementation and nothing else changes.
@DependencyClient
struct AdvisorsClient: Sendable {
    var fetchAll: @Sendable () async throws -> [Advisor]
}

extension AdvisorsClient {
    /// Serves the sample advisors after an optional simulated network delay.
    static func mock(latency: Duration = .zero) -> Self {
        Self(fetchAll: {
            try await Task.sleep(for: latency)
            return mockAdvisors
        })
    }

    /// Illustrative sample advisors — the same fictional people as the Flutter demo.
    static let mockAdvisors: [Advisor] = [
        Advisor(id: "a1", name: "Maya Okafor", title: "Founder, neighbourhood bakery group", level: 3,
                why: "I started with one oven and a borrowed van. I know exactly how scary the first month feels.",
                skills: ["Food business", "Pricing", "Hiring first staff"], style: "Direct and practical",
                offers: [.sessions, .content], accent: .coral),
        Advisor(id: "a2", name: "Daniel Reyes", title: "Ex-CFO, two bootstrapped exits", level: 4,
                why: "Cash flow kills more good ideas than competition does. I help you see it coming.",
                skills: ["Capital readiness", "Cash flow", "Grants"], style: "Numbers first, jargon never",
                offers: [.sessions, .events], accent: .gold),
        Advisor(id: "a3", name: "Priya Nair", title: "Product lead turned solo founder", level: 3,
                why: "I left a great job for an idea that scared me. I can help you de-risk the leap.",
                skills: ["Software products", "MVPs", "Side-to-full-time"], style: "Warm, structured",
                offers: [.sessions, .content, .events], accent: .violet),
        Advisor(id: "a4", name: "Jordan Ellis", title: "Small-business attorney", level: 2,
                why: "Most legal mistakes are made in week one. I make sure you do not make them.",
                skills: ["LLC vs sole prop", "Contracts", "Trademarks"], style: "Plain English",
                offers: [.sessions, .content], accent: .sky),
        Advisor(id: "a5", name: "Amara Diallo", title: "Community builder and coach", level: 4,
                why: "Isolation is the silent killer of founders. Let me help you find your people.",
                skills: ["Community", "Mindset", "Accountability"], style: "Encouraging, honest",
                offers: [.sessions, .events], accent: .teal),
        Advisor(id: "a6", name: "Tomás Herrera", title: "Marketing strategist, 15 years in local retail", level: 3,
                why: "You do not need a big budget — you need a clear message and the right ten customers.",
                skills: ["Positioning", "First customers", "Local marketing"], style: "Energetic, hands-on",
                offers: [.sessions, .content], accent: .gold),
    ]
}

extension AdvisorsClient: DependencyKey {
    // No backend in the demo: "live" is the mock with a realistic delay.
    static let liveValue: Self = .mock(latency: .milliseconds(450))
    static let previewValue: Self = .mock()
    // Unimplemented: a test that reaches this client without overriding it fails, so each
    // test states exactly what the feature touches.
    static let testValue = Self()
}

extension DependencyValues {
    var advisorsClient: AdvisorsClient {
        get { self[AdvisorsClient.self] }
        set { self[AdvisorsClient.self] = newValue }
    }
}
