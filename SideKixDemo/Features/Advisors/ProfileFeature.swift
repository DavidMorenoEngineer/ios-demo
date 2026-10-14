import ComposableArchitecture
import Foundation

@Reducer
struct ProfileFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        let advisor: Advisor
        var isImmersive = false
        var toast: String?
        var id: Advisor.ID { advisor.id }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case expandTapped
        case bookTapped
        case bookingResponse(Result<String, any Error>)
        case toastDismissed
    }

    private enum CancelID { case toast }

    @Dependency(\.bookingClient) var bookingClient
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .expandTapped:
                state.isImmersive = true
                return .none

            case .bookTapped:
                let advisor = state.advisor
                return .run { send in
                    do {
                        await send(.bookingResponse(.success(try await bookingClient.request(advisor))))
                    } catch {
                        await send(.bookingResponse(.failure(error)))
                    }
                }

            case .bookingResponse(let result):
                switch result {
                case .success(let message): state.toast = message
                case .failure: state.toast = "Couldn’t send your request. Please try again."
                }
                return .run { send in
                    try await clock.sleep(for: .seconds(3))
                    await send(.toastDismissed)
                }
                .cancellable(id: CancelID.toast, cancelInFlight: true)

            case .toastDismissed:
                state.toast = nil
                return .none
            }
        }
    }
}
