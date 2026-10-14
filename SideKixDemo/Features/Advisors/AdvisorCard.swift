import SwiftUI

/// Phone list card: avatar, name, a two-line quote and the first skills.
struct AdvisorCard: View {
    let advisor: Advisor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                AvatarView(advisor: advisor, size: 60)
                VStack(alignment: .leading, spacing: 3) {
                    Text(advisor.name).font(.sxDisplay(.title2)).foregroundStyle(SX.goldLight)
                    Text(advisor.title).font(.sxBody(.footnote)).foregroundStyle(SX.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                LevelBadge(text: advisor.levelLabel)
            }
            Text("“\(advisor.why)”")
                .font(.sxDisplay(.callout, weight: .medium)).italic()
                .foregroundStyle(SX.textSoft)
                .lineLimit(2)
            HStack {
                FlowLayout { ForEach(advisor.skills.prefix(2), id: \.self) { TagChip(text: $0) } }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(SX.dim)
            }
        }
        .padding(18)
        .background(SX.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(SX.line, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Sidebar row used in the iPad split view: a compact card with a skill preview,
/// an accent-tinted background and a gold outline when selected.
struct AdvisorRow: View {
    let advisor: Advisor
    var isSelected = false

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(advisor: advisor, size: 56)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(advisor.name).font(.sxDisplay(.title3)).foregroundStyle(SX.goldLight)
                    Spacer(minLength: 6)
                    Text(advisor.levelLabel).sxLabelStyle(isSelected ? SX.goldInk : SX.gold)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(isSelected ? SX.gold : .clear, in: Capsule())
                        .overlay(Capsule().strokeBorder(SX.gold.opacity(0.7), lineWidth: 1))
                }
                Text(advisor.title).font(.sxBody(.caption)).foregroundStyle(SX.muted).lineLimit(1)
                HStack(spacing: 6) {
                    ForEach(advisor.skills.prefix(2), id: \.self) { skill in
                        Text(skill)
                            .font(.sxBody(.caption2))
                            .foregroundStyle(SX.textSoft)
                            .lineLimit(1)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(SX.surfaceHigh, in: Capsule())
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [advisor.accent.color.opacity(isSelected ? 0.22 : 0.07), SX.surface],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(isSelected ? SX.gold : SX.line, lineWidth: isSelected ? 1.5 : 1)
        )
        .shadow(color: isSelected ? SX.gold.opacity(0.18) : .clear, radius: 12, y: 4)
        .animation(.snappy(duration: 0.2), value: isSelected)
        .accessibilityElement(children: .combine)
    }
}

struct OfferChips: View {
    @Binding var selection: Offer?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", symbol: nil, isOn: selection == nil) { selection = nil }
                ForEach(Offer.allCases, id: \.self) { offer in
                    chip(offer.rawValue, symbol: offer.symbol, isOn: selection == offer) {
                        selection = selection == offer ? nil : offer
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollClipDisabled()
    }

    private func chip(_ title: String, symbol: String?, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol).font(.caption) }
                Text(title).font(.sxBody(.subheadline, weight: .medium))
            }
            .foregroundStyle(isOn ? SX.goldInk : SX.textSoft)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(isOn ? SX.gold : SX.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isOn ? SX.gold : SX.line))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
