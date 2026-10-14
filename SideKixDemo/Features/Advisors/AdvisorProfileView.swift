import ComposableArchitecture
import SwiftUI

/// Advisor profile. Adapts to the width it is given rather than the device:
/// a two-column layout when there is room (iPad detail pane), one column otherwise.
struct AdvisorProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    @Environment(\.isRegularWidth) private var isRegular
    private var advisor: Advisor { store.advisor }
    /// Measured width of the content area; decides one vs two columns.
    @State private var availableWidth: CGFloat = 0
    private let twoColumnMinWidth: CGFloat = 760

    var body: some View {
        ScrollView {
            Group {
                if availableWidth >= twoColumnMinWidth { twoColumn } else { oneColumn }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 1040)
            .frame(maxWidth: .infinity)
        }
        .background(SX.bg)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
        .safeAreaInset(edge: .bottom) { bookBar }
        .toast(store.toast)
        .navigationTitle(advisor.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { store.send(.expandTapped) } label: {
                    Label("Full screen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .accessibilityIdentifier("profile.fullscreen")
            }
        }
        .fullScreenCover(isPresented: $store.isImmersive) {
            ImmersiveProfileView(advisor: advisor) { store.send(.bookTapped) }
        }
    }

    // MARK: Layouts

    private var oneColumn: some View {
        VStack(spacing: 16) {
            hero
            quote
            skills
            approach
            offers
        }
    }

    private var twoColumn: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(spacing: 16) { hero; offers }
                .frame(width: 300)
            VStack(spacing: 16) { quote; skills; approach }
        }
    }

    // MARK: Sections

    private var hero: some View {
        VStack(spacing: 14) {
            AvatarView(advisor: advisor, size: isRegular ? 132 : 112)
            VStack(spacing: 6) {
                Text(advisor.name).font(.sxDisplay(isRegular ? .largeTitle : .title)).foregroundStyle(SX.goldLight)
                Text(advisor.title).font(.sxBody()).foregroundStyle(SX.muted).multilineTextAlignment(.center)
            }
            LevelBadge(text: advisor.levelLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24).padding(.horizontal, 16)
        .background(
            LinearGradient(colors: [advisor.accent.color.opacity(0.22), SX.surface], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(SX.line))
        .accessibilityElement(children: .combine)
    }

    private var quote: some View {
        SectionCard(title: "Why I do this", accent: advisor.accent.color) {
            Text("“\(advisor.why)”")
                .font(.sxDisplay(isRegular ? .title : .title3, weight: .medium))
                .foregroundStyle(SX.goldLight)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var skills: some View {
        SectionCard(title: "What I know") {
            FlowLayout(spacing: 8) { ForEach(advisor.skills, id: \.self) { TagChip(text: $0) } }
        }
    }

    private var approach: some View {
        SectionCard(title: "How I work") {
            Label(advisor.style, systemImage: "quote.bubble")
                .font(.sxBody(.body)).foregroundStyle(SX.text)
        }
    }

    private var offers: some View {
        SectionCard(title: "Offers") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(advisor.offers, id: \.self) { offer in
                    HStack(spacing: 12) {
                        Image(systemName: offer.symbol)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(SX.gold)
                            .background(SX.surfaceHigh, in: Circle())
                        VStack(alignment: .leading, spacing: 0) {
                            Text(offer.rawValue).font(.sxBody(.subheadline, weight: .semibold)).foregroundStyle(SX.text)
                            Text(offer.blurb).font(.sxBody(.caption)).foregroundStyle(SX.muted)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var bookBar: some View {
        Button("Book a Session") { store.send(.bookTapped) }
            .buttonStyle(GoldButtonStyle())
            .frame(maxWidth: 520)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial.opacity(0.9))
            .background(SX.bg.opacity(0.6))
            .accessibilityIdentifier("profile.book")
    }
}

/// Full-screen, editorial presentation of a profile — the website's
/// "one idea per screen" treatment, for showing an advisor off on a big display.
struct ImmersiveProfileView: View {
    let advisor: Advisor
    var onBook: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        ZStack(alignment: .topTrailing) {
            background
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(spacing: 16) {
                        AvatarView(advisor: advisor, size: 72)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(advisor.name).font(.sxDisplay(.title)).foregroundStyle(SX.goldLight)
                            Text(advisor.title).font(.sxBody()).foregroundStyle(SX.muted)
                        }
                    }
                    Text("Why I do this").sxLabelStyle(advisor.accent.color)
                    Text("“\(advisor.why)”")
                        .font(.system(size: hSize == .regular ? 54 : 34, weight: .medium, design: .serif))
                        .foregroundStyle(SX.goldLight)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    FlowLayout(spacing: 8) {
                        LevelBadge(text: advisor.levelLabel)
                        ForEach(advisor.skills, id: \.self) { TagChip(text: $0) }
                    }
                    Text("\(advisor.style)  ·  \(advisor.offers.map(\.rawValue).joined(separator: " · "))")
                        .font(.sxBody()).foregroundStyle(SX.muted)
                    Button("Book a Session") { dismiss(); onBook() }
                        .buttonStyle(GoldButtonStyle())
                        .frame(maxWidth: 360)
                }
                .padding(.horizontal, hSize == .regular ? 72 : 24)
                .padding(.vertical, 72)
                .frame(maxWidth: 900, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline).foregroundStyle(SX.goldLight)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(16)
            .accessibilityLabel("Close")
            .accessibilityIdentifier("immersive.close")
        }
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        ZStack {
            SX.bgDeep
            RadialGradient(colors: [advisor.accent.color.opacity(0.35), .clear], center: .topLeading, startRadius: 20, endRadius: 700)
            Text(advisor.initials)
                .font(.system(size: hSize == .regular ? 420 : 200, weight: .bold, design: .serif))
                .foregroundStyle(SX.goldLight.opacity(0.04))
                .offset(x: hSize == .regular ? 120 : 40, y: hSize == .regular ? 200 : 260)
        }
        .ignoresSafeArea()
    }
}
