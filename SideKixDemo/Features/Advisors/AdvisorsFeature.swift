import ComposableArchitecture
import Foundation

@Reducer
struct AdvisorsFeature {
    @ObservableState
    struct State: Equatable {
        enum Phase: Equatable {
            case loading
            case loaded
            case failed(String)
        }

        var phase: Phase = .loading
        /// The single copy of the advisor data. Everything else is derived from it.
        var advisors: IdentifiedArrayOf<Advisor> = []
        var query = ""
        var offerFilter: Offer?
        /// iPhone: profiles pushed onto the navigation stack. A child lives while its screen does.
        var path = StackState<ProfileFeature.State>()
        /// iPad: the profile shown in the detail pane. Selecting another replaces it.
        @Presents var detail: ProfileFeature.State?
        /// Set once the split view is on screen, so the first advisor is shown by default.
        var autoSelectsFirst = false
        /// Open this advisor as soon as the list has loaded (a deep link).
        var pendingAdvisorID: Advisor.ID?
        var pendingFullScreen = false

        var results: [Advisor] {
            Array(advisors.filter { $0.matches(query) && (offerFilter.map($0.offers.contains) ?? true) })
        }

        var isFiltering: Bool { offerFilter != nil || !query.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case task
        case retryTapped
        case advisorsResponse(Result<[Advisor], any Error>)
        case clearFiltersTapped
        case advisorSelected(Advisor.ID?)
        case splitViewAppeared
        case path(StackActionOf<ProfileFeature>)
        case detail(PresentationAction<ProfileFeature.Action>)
    }

    @Dependency(\.advisorsClient) var advisorsClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .path, .detail:
                return .none

            case .task, .retryTapped:
                state.phase = .loading
                return .run { send in
                    do {
                        await send(.advisorsResponse(.success(try await advisorsClient.fetchAll())))
                    } catch {
                        await send(.advisorsResponse(.failure(error)))
                    }
                }

            case .advisorsResponse(.success(let advisors)):
                state.advisors = IdentifiedArray(uniqueElements: advisors)
                state.phase = .loaded
                if let id = state.pendingAdvisorID, let advisor = state.advisors[id: id] {
                    state.pendingAdvisorID = nil
                    let profile = ProfileFeature.State(advisor: advisor, isImmersive: state.pendingFullScreen)
                    // Whichever layout is on screen (stack or split view) shows its own copy.
                    state.path.append(profile)
                    state.detail = profile
                } else if state.autoSelectsFirst, state.detail == nil, let first = state.advisors.first {
                    state.detail = ProfileFeature.State(advisor: first)
                }
                return .none

            case .advisorsResponse(.failure):
                state.phase = .failed("We couldn’t reach the advisors right now.")
                return .none

            case .clearFiltersTapped:
                state.query = ""
                state.offerFilter = nil
                return .none

            case .advisorSelected(let id):
                guard id != state.detail?.id else { return .none }
                state.detail = id.flatMap { state.advisors[id: $0] }.map { ProfileFeature.State(advisor: $0) }
                return .none

            case .splitViewAppeared:
                state.autoSelectsFirst = true
                if state.detail == nil, let first = state.advisors.first {
                    state.detail = ProfileFeature.State(advisor: first)
                }
                return .none
            }
        }
        .forEach(\.path, action: \.path) { ProfileFeature() }
        .ifLet(\.$detail, action: \.detail) { ProfileFeature() }
    }
}
