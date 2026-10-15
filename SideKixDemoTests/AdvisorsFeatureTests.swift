import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import SideKixDemo

@MainActor
final class AdvisorsFeatureTests: XCTestCase {
    private let mock = AdvisorsClient.mockAdvisors
    private var priya: Advisor { mock[2] }

    private var mockList: IdentifiedArrayOf<Advisor> { IdentifiedArray(uniqueElements: mock) }

    /// State as it looks after a successful load.
    private func loadedState() -> AdvisorsFeature.State {
        var state = AdvisorsFeature.State()
        state.advisors = mockList
        state.phase = .loaded
        return state
    }

    // MARK: Loading

    func testLoadsAdvisorsFromClient() async {
        let store = TestStore(initialState: AdvisorsFeature.State()) {
            AdvisorsFeature()
        } withDependencies: {
            $0.advisorsClient.fetchAll = { AdvisorsClient.mockAdvisors }
        }
        await store.send(.task)
        await store.receive(\.advisorsResponse.success) {
            $0.advisors = self.mockList
            $0.phase = .loaded
        }
    }

    func testFailureShowsMessageAndRetryRecovers() async {
        let attempts = LockIsolated(0)
        let store = TestStore(initialState: AdvisorsFeature.State()) {
            AdvisorsFeature()
        } withDependencies: {
            // Fails the first time, then recovers — one closure, so the retry can't race a dependency swap.
            $0.advisorsClient.fetchAll = {
                if attempts.withValue({ $0 += 1; return $0 }) == 1 { throw URLError(.notConnectedToInternet) }
                return AdvisorsClient.mockAdvisors
            }
        }
        await store.send(.task)
        await store.receive(\.advisorsResponse.failure) {
            $0.phase = .failed("We couldn’t reach the advisors right now.")
        }

        await store.send(.retryTapped) { $0.phase = .loading }
        await store.receive(\.advisorsResponse.success) {
            $0.advisors = self.mockList
            $0.phase = .loaded
        }
    }

    // MARK: Search and filter

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

    // MARK: iPad detail pane

    func testSelectingAnAdvisorShowsAndReplacesItsProfile() async {
        let store = TestStore(initialState: loadedState()) { AdvisorsFeature() }

        await store.send(.advisorSelected("a3")) {
            $0.detail = ProfileFeature.State(advisor: self.priya)
        }
        // Selecting the same row again keeps the open profile (and its state).
        await store.send(.advisorSelected("a3"))
        await store.send(.advisorSelected("a1")) {
            $0.detail = ProfileFeature.State(advisor: self.mock[0])
        }
        await store.send(.advisorSelected(nil)) { $0.detail = nil }
    }

    func testSplitViewShowsTheFirstAdvisorOnceLoaded() async {
        // Appears before the data arrives…
        let store = TestStore(initialState: AdvisorsFeature.State()) {
            AdvisorsFeature()
        } withDependencies: {
            $0.advisorsClient.fetchAll = { AdvisorsClient.mockAdvisors }
        }
        await store.send(.splitViewAppeared) { $0.autoSelectsFirst = true }
        await store.send(.task)
        await store.receive(\.advisorsResponse.success) {
            $0.advisors = self.mockList
            $0.phase = .loaded
            $0.detail = ProfileFeature.State(advisor: self.mock[0])
        }
    }

    func testSplitViewAppearingAfterLoadSelectsTheFirstAdvisor() async {
        let store = TestStore(initialState: loadedState()) { AdvisorsFeature() }
        await store.send(.splitViewAppeared) {
            $0.autoSelectsFirst = true
            $0.detail = ProfileFeature.State(advisor: self.mock[0])
        }
    }

    // MARK: Deep link

    func testPendingAdvisorOpensOnceLoaded() async {
        let store = TestStore(
            initialState: AdvisorsFeature.State(pendingAdvisorID: "a3", pendingFullScreen: true)
        ) {
            AdvisorsFeature()
        } withDependencies: {
            $0.advisorsClient.fetchAll = { AdvisorsClient.mockAdvisors }
        }
        // Stack element ids come from a generator the test closure does not share, so check them below.
        store.exhaustivity = .off
        await store.send(.task)
        await store.receive(\.advisorsResponse.success) {
            $0.phase = .loaded
            $0.pendingAdvisorID = nil
            $0.detail = ProfileFeature.State(advisor: self.priya, isImmersive: true)
        }
        XCTAssertEqual(store.state.path.count, 1)
        XCTAssertEqual(store.state.path.first?.advisor.id, "a3")
        XCTAssertEqual(store.state.path.first?.isImmersive, true)
    }

    // MARK: One copy of the data

    func testReloadingKeepsTheOpenProfileAndItsToast() async {
        var initial = loadedState()
        var profile = ProfileFeature.State(advisor: priya)
        profile.toast = "Sessions open in phase two — noted your interest in Priya."
        initial.detail = profile
        initial.path.append(profile)

        let store = TestStore(initialState: initial) {
            AdvisorsFeature()
        } withDependencies: {
            $0.advisorsClient.fetchAll = { AdvisorsClient.mockAdvisors }
        }
        await store.send(.retryTapped) { $0.phase = .loading }
        // Nothing about the open profiles changes: no state closure touches `detail` or `path`.
        await store.receive(\.advisorsResponse.success) { $0.phase = .loaded }
        XCTAssertEqual(store.state.detail?.toast, profile.toast)
        XCTAssertEqual(store.state.path.first?.toast, profile.toast)
    }

    // MARK: Child lifetime

    func testPoppingAProfileCancelsItsPendingToastTimer() async {
        let clock = TestClock()
        var initial = loadedState()
        initial.path.append(ProfileFeature.State(advisor: priya))

        let store = TestStore(initialState: initial) {
            AdvisorsFeature()
        } withDependencies: {
            $0.bookingClient = .mock()
            $0.continuousClock = clock
        }
        let id = store.state.path.ids[0]

        await store.send(.path(.element(id: id, action: .bookTapped)))
        await store.receive(\.path[id: id].bookingResponse.success) {
            $0.path[id: id]?.toast = "Sessions open in phase two — noted your interest in Priya."
        }
        // The three-second dismissal timer is now running. Going back must cancel it; the
        // store would fail the test if an effect outlived its screen.
        await store.send(.path(.popFrom(id: id))) { $0.path = StackState() }
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
            $0.bookingClient = .mock()
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
