import SwiftUI

/// A list row for one heart-rate zone: a colour dot, a title, and a trailing detail.
///
/// At accessibility text sizes the detail moves below the title instead of being squeezed
/// beside it. Text is passed in already localized, because DesignSystem holds no wording.
///
/// ```swift
/// ZoneRow(tone: .zone3, title: "3. Aerobic", detail: "from 133 BPM", isCurrent: true)
/// ```
public struct ZoneRow: View {
    let tone: ZoneTone
    let title: String
    let detail: String
    let isCurrent: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 10

    public init(tone: ZoneTone, title: String, detail: String, isCurrent: Bool = false) {
        self.tone = tone
        self.title = title
        self.detail = detail
        self.isCurrent = isCurrent
    }

    public var body: some View {
        // `AnyLayout` switches between a row and a column while keeping the same child views,
        // so SwiftUI can animate the change instead of rebuilding them.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.s))

        layout {
            HStack(spacing: Spacing.s) {
                Circle()
                    .fill(.zone(tone))
                    .frame(width: dotSize, height: dotSize)
                Text(title)
                    .fontWeight(isCurrent ? .bold : .regular)
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: Spacing.s)
            }
            Text(detail)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        // VoiceOver reads one element ("3. Aerobic, from 133 BPM, Selected").
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

// MARK: - Previews

private struct ZoneRowsPreview: View {
    var body: some View {
        List {
            ZoneRow(tone: .zone1, title: "1. Recovery", detail: "from 95 BPM")
            ZoneRow(tone: .zone2, title: "2. Endurance", detail: "from 114 BPM")
            ZoneRow(tone: .zone3, title: "3. Aerobic", detail: "from 133 BPM", isCurrent: true)
            ZoneRow(tone: .zone4, title: "4. Threshold", detail: "from 152 BPM")
            ZoneRow(tone: .zone5, title: "5. Maximum", detail: "from 171 BPM")
        }
    }
}

#Preview("Default text size") {
    ZoneRowsPreview()
}

#Preview("Accessibility text size: detail moves below") {
    ZoneRowsPreview()
        .dynamicTypeSize(.accessibility3)
}
