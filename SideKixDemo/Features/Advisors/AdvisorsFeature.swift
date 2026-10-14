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
        var advisors: [Advisor] = []
        var query = ""
        var offerFilter: Offer?
        /// Selected advisor in the iPad split view.
        var selection: Advisor.ID?
        /// Pushed profiles in the iPhone navigation stack.
        var path: [Advisor.ID] = []
        var profiles: IdentifiedArrayOf<ProfileFeature.State> = []

        var results: [Advisor] {
            advisors.filter { $0.matches(query) && (offerFilter.map($0.offers.contains) ?? true) }
        }

        var isFiltering: Bool { offerFilter != nil || !query.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case task
        case retryTapped
        case advisorsResponse(Result<[Advisor], any Error>)
        case clearFiltersTapped
        case advisorOpened(Advisor.ID)
        case profiles(IdentifiedActionOf<ProfileFeature>)
    }

    @Dependency(\.advisorsClient) var advisorsClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .profiles:
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
                state.advisors = advisors
                state.profiles = IdentifiedArray(uniqueElements: advisors.map { ProfileFeature.State(advisor: $0) })
                if state.selection == nil { state.selection = advisors.first?.id }
                state.phase = .loaded
                return .none

            case .advisorsResponse(.failure):
                state.phase = .failed("We couldn’t reach the advisors right now.")
                return .none

            case .clearFiltersTapped:
                state.query = ""
                state.offerFilter = nil
                return .none

            case .advisorOpened(let id):
                guard state.profiles[id: id] != nil else { return .none }
                state.selection = id
                if state.path.last != id { state.path = [id] }
                return .none
            }
        }
        .forEach(\.profiles, action: \.profiles) { ProfileFeature() }
    }
}
