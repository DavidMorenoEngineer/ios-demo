import SwiftUI

// Things that are genuinely UI — scrolling for a screenshot — live here, apart from the
// feature views, and compile to nothing in release builds.

#if DEBUG
private struct DemoScroll: ViewModifier {
    let proxy: ScrollViewProxy
    let isLoaded: Bool

    func body(content: Content) -> some View {
        content.onChange(of: isLoaded) { _, loaded in
            // `-demoScrollTo a3`: slide a card up under the translucent top bar.
            if loaded, let id = DemoOptions.current.scrollTo {
                proxy.scrollTo(id, anchor: UnitPoint(x: 0.5, y: 0.22))
            }
        }
    }
}

extension View {
    func demoScroll(proxy: ScrollViewProxy, isLoaded: Bool) -> some View {
        modifier(DemoScroll(proxy: proxy, isLoaded: isLoaded))
    }
}
#else
extension View {
    func demoScroll(proxy: ScrollViewProxy, isLoaded: Bool) -> some View { self }
}
#endif
