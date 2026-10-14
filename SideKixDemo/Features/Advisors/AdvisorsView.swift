import ComposableArchitecture
import SwiftUI

/// Picks the navigation model from the horizontal size class, so the same code
/// handles iPhone, iPad, iPad split-screen and Slide Over.
struct AdvisorsView: View {
    @Bindable var store: StoreOf<AdvisorsFeature>
    @Environment(\.horizontalSizeClass) private var hSize
    private let demo = DemoOptions.current

    var body: some View {
        Group {
            if hSize == .regular {
                AdvisorsSplitView(store: store)
            } else {
                AdvisorsStackView(store: store)
            }
        }
        .environment(\.isRegularWidth, hSize == .regular)
        .tint(SX.gold)
        .task {
            await store.send(.task).finish()
            await applyDemo()
        }
    }

    /// Puts the app in a specific state for screenshots (see `DemoOptions`).
    private func applyDemo() async {
        if demo.landscape,
           let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            try? await Task.sleep(for: .seconds(1))
        }
        if let query = demo.query { store.send(.binding(.set(\.query, query))) }
        if let offer = demo.offer { store.send(.binding(.set(\.offerFilter, offer))) }
        if let id = demo.advisorID {
            store.send(.advisorOpened(id))
            if demo.immersive {
                // Let the push finish first; a real user taps after it settles.
                try? await Task.sleep(for: .seconds(1.2))
                store.send(.profiles(.element(id: id, action: .expandTapped)))
            }
        }
    }
}

// MARK: - iPhone

private struct AdvisorsStackView: View {
    @Bindable var store: StoreOf<AdvisorsFeature>

    var body: some View {
        NavigationStack(path: $store.path) {
            ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    header
                    OfferChips(selection: $store.offerFilter).padding(.horizontal, -20)
                    content
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: store.phase) { _, phase in
                // Demo only: scroll a card up under the translucent bar.
                if phase == .loaded, let id = DemoOptions.current.scrollTo {
                    proxy.scrollTo(id, anchor: UnitPoint(x: 0.5, y: 0.22))
                }
            }
            .background(SX.bg)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .navigationDestination(for: Advisor.ID.self) { id in
                if let profile = store.scope(state: \.profiles[id: id], action: \.profiles[id: id]) {
                    AdvisorProfileView(store: profile)
                }
            }
            }
        }
    }

    /// Title and search, on a dark, slightly translucent band. Cards scroll underneath
    /// it and show through as a soft shadow.
    private var topBar: some View {
        VStack(spacing: 10) {
            Text("Advisors").font(.sxDisplay(.headline)).foregroundStyle(SX.goldLight)
            SearchField(text: $store.query, prompt: "Search name, skill or topic")
        }
        .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(SX.bgDeep.opacity(0.5))
            }
            .overlay(alignment: .bottom) { Rectangle().fill(SX.line.opacity(0.5)).frame(height: 0.5) }
            .ignoresSafeArea(edges: .top)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("In your corner").sxLabelStyle()
            Text("Meet the Advisors who’ve been there.")
                .font(.sxDisplay(.largeTitle)).foregroundStyle(SX.goldLight)
                .fixedSize(horizontal: false, vertical: true)
            Text("Tap an advisor to see why they do this, what they know, and how they work.")
                .font(.sxBody()).foregroundStyle(SX.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8).padding(.bottom, 4)
    }

    @ViewBuilder private var content: some View {
        switch store.phase {
        case .loading:
            ForEach(0..<3, id: \.self) { _ in SkeletonCard() }
        case .failed(let message):
            EmptyStateView(symbol: "wifi.exclamationmark", title: "Something went wrong", message: message,
                           actionTitle: "Try again") { store.send(.retryTapped) }
        case .loaded:
            if store.results.isEmpty {
                EmptyStateView(symbol: "magnifyingglass", title: "No advisors match",
                               message: "Try a different skill or clear the filters.",
                               actionTitle: "Clear filters") { withAnimation { _ = store.send(.clearFiltersTapped) } }
            } else {
                ForEach(store.results) { advisor in
                    NavigationLink(value: advisor.id) { AdvisorCard(advisor: advisor) }
                        .buttonStyle(.plain)
                        .id(advisor.id)
                        .accessibilityIdentifier("advisor.\(advisor.id)")
                }
                Text("Illustrative sample advisors, written for this demo — not real people.")
                    .font(.sxBody(.caption)).foregroundStyle(SX.dim).padding(.top, 8)
            }
        }
    }
}

// MARK: - iPad

private struct AdvisorsSplitView: View {
    @Bindable var store: StoreOf<AdvisorsFeature>
    @State private var visibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            sidebar
                .navigationTitle("Advisors")
                .navigationSplitViewColumnWidth(min: 400, ideal: 420, max: 460)
        } detail: {
            NavigationStack {
                if let id = store.selection,
                   let profile = store.scope(state: \.profiles[id: id], action: \.profiles[id: id]) {
                    AdvisorProfileView(store: profile).id(id)
                } else {
                    EmptyStateView(symbol: "person.2", title: "Pick an advisor",
                                   message: "Choose someone from the list to see their profile.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity).background(SX.bg)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("In your corner").sxLabelStyle()
                Text("Meet the Advisors who’ve been there.")
                    .font(.sxDisplay(.title)).foregroundStyle(SX.goldLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)

            OfferChips(selection: $store.offerFilter).padding(.bottom, 8)

            switch store.phase {
            case .loading:
                ProgressView().tint(SX.gold).frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                EmptyStateView(symbol: "wifi.exclamationmark", title: "Something went wrong", message: message,
                               actionTitle: "Try again") { store.send(.retryTapped) }
                Spacer()
            case .loaded:
                if store.results.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass", title: "No advisors match",
                                   message: "Try a different skill or clear the filters.",
                                   actionTitle: "Clear filters") { withAnimation { _ = store.send(.clearFiltersTapped) } }
                    Spacer()
                } else {
                    List(store.results, selection: $store.selection) { advisor in
                        AdvisorRow(advisor: advisor, isSelected: store.selection == advisor.id)
                            .tag(advisor.id)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .accessibilityIdentifier("advisor.\(advisor.id)")
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .background(SX.bg)
        .searchable(text: $store.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search name, skill or topic")
    }
}

private struct SkeletonCard: View {
    @State private var pulse = false
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(SX.surface)
            .frame(height: 170)
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(SX.line))
            .opacity(pulse ? 0.45 : 1)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
            .accessibilityLabel("Loading advisors")
    }
}
