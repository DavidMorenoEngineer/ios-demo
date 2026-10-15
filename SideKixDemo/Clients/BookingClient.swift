import ComposableArchitecture
import Foundation

/// Requests a session with an advisor. Sessions open in a later phase, so the
/// mock acknowledges the interest and returns the confirmation to show.
@DependencyClient
struct BookingClient: Sendable {
    var request: @Sendable (_ advisor: Advisor) async throws -> String
}

extension BookingClient {
    static func mock(latency: Duration = .zero) -> Self {
        Self(request: { advisor in
            try await Task.sleep(for: latency)
            return "Sessions open in phase two — noted your interest in \(advisor.firstName)."
        })
    }
}

extension BookingClient: DependencyKey {
    static let liveValue: Self = .mock(latency: .milliseconds(300))
    static let previewValue: Self = .mock()
    static let testValue = Self()
}

extension DependencyValues {
    var bookingClient: BookingClient {
        get { self[BookingClient.self] }
        set { self[BookingClient.self] = newValue }
    }
}
