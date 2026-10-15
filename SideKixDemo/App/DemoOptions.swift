import Foundation

/// Launch arguments that start the app in a specific state — used to make screenshots:
/// `-demoAdvisor a3 -demoImmersive -demoFilter events -demoQuery maya`.
/// They only feed the store's *initial state*; the reducer does the rest. Release builds ignore them.
struct DemoOptions {
    var advisorID: String?
    var immersive = false
    var offer: Offer?
    var query: String?
    var scrollTo: String?

    #if DEBUG
    static let current: DemoOptions = {
        let args = ProcessInfo.processInfo.arguments
        func value(_ flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), args.indices.contains(i + 1) else { return nil }
            return args[i + 1]
        }
        return DemoOptions(
            advisorID: value("-demoAdvisor"),
            immersive: args.contains("-demoImmersive"),
            offer: value("-demoFilter").flatMap { raw in Offer.allCases.first { $0.rawValue.lowercased() == raw.lowercased() } },
            query: value("-demoQuery"),
            scrollTo: value("-demoScrollTo")
        )
    }()
    #else
    static let current = DemoOptions()
    #endif
}
