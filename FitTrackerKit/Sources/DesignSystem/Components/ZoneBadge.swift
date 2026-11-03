import SwiftUI

/// A square badge showing a heart-rate zone number on its zone colour, or "–" when resting.
///
/// The badge is content, not a control, so it uses a solid fill rather than Liquid Glass.
/// It scales with Dynamic Type. It has no accessibility label of its own; combine it with the
/// zone's name in the parent (`.accessibilityElement(children: .combine)`).
///
/// ```swift
/// ZoneBadge(tone: .zone3)
/// ZoneBadge(tone: nil)   // resting
/// ```
public struct ZoneBadge: View {
    let tone: ZoneTone?

    /// 72pt at the default text size, growing and shrinking with the user's text size setting.
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 72

    public init(tone: ZoneTone?) {
        self.tone = tone
    }

    public var body: some View {
        // `verbatim:` because a number isn't something to translate.
        Text(verbatim: tone.map { "\($0.rawValue)" } ?? "–")
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background, in: .rect(cornerRadius: size * 0.22))
    }

    private var foreground: AnyShapeStyle {
        tone.map { AnyShapeStyle(.onZone($0)) } ?? AnyShapeStyle(.secondary)
    }

    private var background: AnyShapeStyle {
        tone.map { AnyShapeStyle(.zone($0)) } ?? AnyShapeStyle(.fill.tertiary)
    }
}

// MARK: - Previews

/// Six badges are wider than an iPhone screen, so the row scrolls rather than clipping.
private struct AllZoneBadges: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ZoneBadge(tone: nil)
                ForEach(ZoneTone.allCases, id: \.self) { ZoneBadge(tone: $0) }
            }
            .padding()
        }
    }
}

#Preview("All zones") {
    AllZoneBadges()
}

#Preview("All zones, dark") {
    AllZoneBadges()
        .preferredColorScheme(.dark)
}

#Preview("Accessibility text size") {
    ZoneBadge(tone: .zone3)
        .dynamicTypeSize(.accessibility3)
}
