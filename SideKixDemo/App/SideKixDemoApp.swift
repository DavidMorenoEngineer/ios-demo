import ComposableArchitecture
import SwiftUI

@main
struct SideKixDemoApp: App {
    private let store: StoreOf<AdvisorsFeature> = {
        let demo = DemoOptions.current
        return Store(initialState: AdvisorsFeature.State(
            query: demo.query ?? "",
            offerFilter: demo.offer,
            pendingAdvisorID: demo.advisorID,
            pendingFullScreen: demo.immersive
        )) { AdvisorsFeature() }
    }()

    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    init() {
        // Serif large/inline titles that match the site's display face.
        func serif(_ size: CGFloat) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: .semibold)
            return base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? base
        }
        // Bar fill is set per screen with `.toolbarBackground`; here only the serif titles.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor(SX.goldLight), .font: serif(18)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(SX.goldLight), .font: serif(34)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UISearchTextField.appearance().backgroundColor = UIColor(SX.surfaceHigh).withAlphaComponent(0.7)
    }

    var body: some Scene {
        WindowGroup {
            if isRunningUnitTests {
                // The unit-test host launches the app; keep it idle so it doesn't hit unimplemented test clients.
                Color.clear
            } else {
                AdvisorsView(store: store)
                    .preferredColorScheme(.dark)
                    .background(SX.bg.ignoresSafeArea())
            }
        }
    }
}
