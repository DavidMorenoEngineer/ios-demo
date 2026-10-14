import ComposableArchitecture
import XCTest
@testable import SideKixDemo

@MainActor
final class AdvisorsFeatureTests: XCTestCase {
    private let mock = AdvisorsClient.mockAdvisors

    /// State as it looks after a successful load, for pure-state tests.
    private func loadedState() -> AdvisorsFeature.State {
        var state = AdvisorsFeature.State()
        state.advisors = mock
        state.phase = .loaded
        return state
    }

    func testLoadsMockAdvisorsFromClient() async {
        let store = TestStore(initialState: AdvisorsFeature.State()) { AdvisorsFeature() }
        await store.send(.task)
        await store.receive(\.advisorsResponse.success) {
            $0.advisors = self.mock
            $0.profiles = IdentifiedArray(uniqueElements: self.mock.map { ProfileFeature.State(advisor: $0) })
            $0.selection = "a1"
            $0.phase = .loaded
        }
    }

    func testFailureShowsMessageAndRetryRecovers() async {
        let store = TestStore(initialState: AdvisorsFeature.State()) {
            AdvisorsFeature()
        } withDependencies: {
            $0.advisorsClient.fetchAll = { throw URLError(.notConnectedToInternet) }
        }
        await store.send(.task)
        await store.receive(\.advisorsResponse.failure) {
            $0.phase = .failed("We couldn’t reach the advisors right now.")
        }

        store.dependencies.advisorsClient = .mock()
        await store.send(.retryTapped) { $0.phase = .loading }
        await store.receive(\.advisorsResponse.success) {
            $0.advisors = self.mock
            $0.profiles = IdentifiedArray(uniqueElements: self.mock.map { ProfileFeature.State(advisor: $0) })
            $0.selection = "a1"
            $0.phase = .loaded
        }
    }

    func testSearchMatchesNameSkillAndStyle() {
        var state = loadedState()
        state.query = "maya"
        XCTAssertEqual(state.results.map(\.id), ["a1"])
        state.query = "trademarks"
        XCTAssertEqual(state.results.map(\.id), ["a4"])
        state.query = "plain english"
        XCTAssertEqual(state.results.map(\.id), ["a4"])
        state.query = "zzz"
        XCTAssertTrue(state.results.isEmpty)
    }

    func testOfferFilterAndClear() async {
        let store = TestStore(initialState: loadedState()) { AdvisorsFeature() }
        await store.send(.binding(.set(\.offerFilter, .events))) { $0.offerFilter = .events }
        XCTAssertEqual(Set(store.state.results.map(\.id)), ["a2", "a3", "a5"])
        XCTAssertTrue(store.state.isFiltering)

        await store.send(.clearFiltersTapped) { $0.offerFilter = nil }
        XCTAssertEqual(store.state.results.count, 6)
        XCTAssertFalse(store.state.isFiltering)
    }

    func testOpeningAnAdvisorSelectsAndPushes() async {
        var initial = loadedState()
        initial.profiles = IdentifiedArray(uniqueElements: mock.map { ProfileFeature.State(advisor: $0) })
        let store = TestStore(initialState: initial) { AdvisorsFeature() }

        await store.send(.advisorOpened("a3")) {
            $0.selection = "a3"
            $0.path = ["a3"]
        }
        await store.send(.advisorOpened("nope"))
    }

    func testInitials() {
        XCTAssertEqual(mock[5].initials, "TH")
    }
}

@MainActor
final class ProfileFeatureTests: XCTestCase {
    private let advisor = AdvisorsClient.mockAdvisors[2]

    func testBookingShowsToastThenDismissesAfterThreeSeconds() async {
        let clock = TestClock()
        let store = TestStore(initialState: ProfileFeature.State(advisor: advisor)) {
            ProfileFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.bookTapped)
        await store.receive(\.bookingResponse.success) {
            $0.toast = "Sessions open in phase two — noted your interest in Priya."
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.toastDismissed) { $0.toast = nil }
    }

    func testBookingFailureShowsFriendlyMessage() async {
        let clock = TestClock()
        let store = TestStore(initialState: ProfileFeature.State(advisor: advisor)) {
            ProfileFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.bookingClient.request = { _ in throw URLError(.timedOut) }
        }

        await store.send(.bookTapped)
        await store.receive(\.bookingResponse.failure) {
            $0.toast = "Couldn’t send your request. Please try again."
        }
        await clock.advance(by: .seconds(3))
        await store.receive(\.toastDismissed) { $0.toast = nil }
    }

    func testExpandAndCloseImmersive() async {
        let store = TestStore(initialState: ProfileFeature.State(advisor: advisor)) { ProfileFeature() }
        await store.send(.expandTapped) { $0.isImmersive = true }
        await store.send(.binding(.set(\.isImmersive, false))) { $0.isImmersive = false }
    }
}
