import Foundation

/// Launch arguments used to put the app in a specific state for screenshots:
/// `-demoAdvisor a3 -demoImmersive -demoFilter events -demoQuery maya -demoLandscape`.
struct DemoOptions {
    var advisorID: String?
    var immersive = false
    var landscape = false
    var scrollTo: String?
    var offer: Offer?
    var query: String?

    static let current: DemoOptions = {
        let args = ProcessInfo.processInfo.arguments
        func value(_ flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), args.indices.contains(i + 1) else { return nil }
            return args[i + 1]
        }
        return DemoOptions(
            advisorID: value("-demoAdvisor"),
            immersive: args.contains("-demoImmersive"),
            landscape: args.contains("-demoLandscape"),
            scrollTo: value("-demoScrollTo"),
            offer: value("-demoFilter").flatMap { raw in Offer.allCases.first { $0.rawValue.lowercased() == raw.lowercased() } },
            query: value("-demoQuery")
        )
    }()
}
