import SwiftUI

/// A large card with generated artwork on top and a title below, for horizontal rows of
/// plans and suggestions.
public struct ArtCard<Badge: View>: View {
    let title: String
    let subtitle: String
    let style: RingStyle
    let kind: SceneArt.Kind
    let seed: Int
    let width: CGFloat?
    let artHeight: CGFloat
    let badge: Badge

    public init(
        title: String,
        subtitle: String,
        style: RingStyle,
        kind: SceneArt.Kind,
        seed: Int,
        width: CGFloat? = 220,
        artHeight: CGFloat = 130,
        @ViewBuilder badge: () -> Badge = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.kind = kind
        self.seed = seed
        self.width = width
        self.artHeight = artHeight
        self.badge = badge()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SceneArt(style: style, kind: kind, seed: seed)
                .frame(height: artHeight)
                .overlay(alignment: .topTrailing) { badge.padding(Spacing.s) }
                .clipShape(.rect(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, Spacing.xs)
        }
        .frame(width: width, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// A small frosted label for the corner of an `ArtCard`, e.g. "12 min".
public struct ArtBadge: View {
    let text: String
    let symbol: String?

    public init(_ text: String, symbol: String? = nil) {
        self.text = text
        self.symbol = symbol
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol) }
            Text(text)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.28), in: .capsule)
    }
}

/// A section title with an optional trailing action, like "For you … See all".
public struct SectionHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let trailing: Trailing

    public init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer()
            trailing.font(.subheadline.weight(.semibold))
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// A horizontally scrolling row that lines its first card up with the screen padding and
/// snaps card by card.
public struct CardRow<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: Spacing.m) { content }
                .scrollTargetLayout()
                .padding(.horizontal, Spacing.m)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled()
        // Cancel the parent's horizontal padding so the row runs edge to edge.
        .padding(.horizontal, -Spacing.m)
    }
}
