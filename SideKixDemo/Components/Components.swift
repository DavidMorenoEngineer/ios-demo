import SwiftUI

struct AvatarView: View {
    let advisor: Advisor
    var size: CGFloat = 64

    var body: some View {
        Text(advisor.initials)
            .font(.system(size: size * 0.42, weight: .semibold, design: .serif))
            .foregroundStyle(SX.goldLight)
            .frame(width: size, height: size)
            .background(
                Circle().fill(LinearGradient(colors: [SX.surfaceHigh, SX.line], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(Circle().strokeBorder(advisor.accent.color.opacity(0.7), lineWidth: size > 90 ? 2 : 1.5))
            .accessibilityHidden(true)
    }
}

struct LevelBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .sxLabelStyle()
            .padding(.horizontal, 10).padding(.vertical, 5)
            .overlay(Capsule().strokeBorder(SX.gold, lineWidth: 1))
    }
}

struct TagChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.sxBody(.caption))
            .foregroundStyle(SX.textSoft)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(SX.surfaceHigh, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sxBody(.headline, weight: .semibold))
            .foregroundStyle(SX.goldInk)
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.vertical, 14).padding(.horizontal, 20)
            .background(
                LinearGradient(colors: [SX.goldLight, SX.gold], startPoint: .top, endPoint: .bottom),
                in: Capsule()
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Wraps children onto new rows, like CSS flex-wrap. Used for skill tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    var accent: Color = SX.gold
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).sxLabelStyle(accent)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(SX.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(SX.line, lineWidth: 1))
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.largeTitle).foregroundStyle(SX.gold)
            Text(title).font(.sxDisplay(.title2))
                .foregroundStyle(SX.goldLight)
            Text(message).font(.sxBody()).foregroundStyle(SX.muted).multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.bordered).tint(SX.gold).padding(.top, 6)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

/// Transient confirmation, shown at the bottom of the screen. The reducer owns
/// when it appears and disappears.
struct Toast: ViewModifier {
    let message: String?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.sxBody(.footnote, weight: .medium))
                    .foregroundStyle(SX.text)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(SX.surfaceHigh, in: Capsule())
                    .overlay(Capsule().strokeBorder(SX.gold.opacity(0.6)))
                    .padding(.bottom, 96).padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: message)
    }
}

extension View {
    func toast(_ message: String?) -> some View { modifier(Toast(message: message)) }
}

/// Dark search field used in the phone's top bar.
struct SearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(SX.dim)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(SX.dim))
                .font(.sxBody(.body))
                .foregroundStyle(SX.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityIdentifier("search.field")
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(SX.dim)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(SX.surfaceHigh.opacity(0.75), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
