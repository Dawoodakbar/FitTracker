import SwiftUI

/// A row of days, each a small ring showing how complete that day was. Used for streaks.
public struct DayDots: View {
    public struct Dot: Identifiable, Equatable, Sendable {
        public let id: Int
        public let label: String
        /// 0...1.
        public let fraction: Double
        public let isToday: Bool

        public init(id: Int, label: String, fraction: Double, isToday: Bool = false) {
            self.id = id
            self.label = label
            self.fraction = fraction
            self.isToday = isToday
        }
    }

    let dots: [Dot]
    let style: RingStyle

    public init(dots: [Dot], style: RingStyle) {
        self.dots = dots
        self.style = style
    }

    public var body: some View {
        HStack {
            ForEach(dots) { dot in
                VStack(spacing: Spacing.xs) {
                    ZStack {
                        ProgressRing(progress: dot.fraction, style: style, lineWidth: 5)
                        if dot.fraction >= 1 {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(style.start)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 34, height: 34)
                    Text(dot.label)
                        .font(.caption2.weight(dot.isToday ? .bold : .regular))
                        .foregroundStyle(dot.isToday ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}
