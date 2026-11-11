import SwiftUI

/// An arc that starts at 12 o'clock and runs clockwise. `progress` animates, so the ring
/// sweeps smoothly to a new value instead of jumping.
struct RingArc: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress),
            clockwise: false
        )
        return path
    }
}

/// A circular progress ring that fills with a spring animation when it appears or changes.
///
/// ```swift
/// ProgressRing(progress: 0.6, style: .sleep, lineWidth: 14)
///     .frame(width: 120, height: 120)
/// ```
public struct ProgressRing: View {
    let progress: Double
    let style: RingStyle
    let lineWidth: CGFloat

    /// What is drawn right now. Starts at 0 and animates to `progress`.
    @State private var shown: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameter progress: 0...1. Values above 1 are drawn as a full ring.
    public init(progress: Double, style: RingStyle, lineWidth: CGFloat = 12) {
        self.progress = min(max(progress, 0), 1)
        self.style = style
        self.lineWidth = lineWidth
        self.shown = 0
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(style.start.opacity(0.18), lineWidth: lineWidth)
            RingArc(progress: shown)
                .stroke(
                    AngularGradient(
                        colors: [style.start, style.end],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * max(shown, 0.001))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .shadow(color: style.end.opacity(0.35), radius: lineWidth / 3)
        }
        .padding(lineWidth / 2)
        .onAppear { animate(to: progress) }
        .onChange(of: progress) { _, newValue in animate(to: newValue) }
        .accessibilityElement()
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }

    private func animate(to value: Double) {
        if reduceMotion {
            shown = value
        } else {
            withAnimation(.spring(duration: 0.9, bounce: 0.2)) { shown = value }
        }
    }
}

/// Several rings nested inside each other, outermost first, like a daily summary.
public struct RingStack: View {
    public struct Ring: Identifiable, Equatable, Sendable {
        public let id: String
        public let progress: Double
        public let style: RingStyle

        public init(id: String, progress: Double, style: RingStyle) {
            self.id = id
            self.progress = progress
            self.style = style
        }
    }

    let rings: [Ring]
    let lineWidth: CGFloat
    let gap: CGFloat

    public init(rings: [Ring], lineWidth: CGFloat = 16, gap: CGFloat = 4) {
        self.rings = rings
        self.lineWidth = lineWidth
        self.gap = gap
    }

    public var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                ProgressRing(progress: ring.progress, style: ring.style, lineWidth: lineWidth)
                    .padding(CGFloat(index) * (lineWidth + gap))
                    .accessibilityLabel(ring.id)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview("Rings") {
    RingStack(rings: [
        .init(id: "Move", progress: 0.8, style: .move),
        .init(id: "Sleep", progress: 0.95, style: .sleep),
        .init(id: "Prayer", progress: 0.6, style: .prayer),
        .init(id: "Medication", progress: 0.5, style: .medication)
    ])
    .frame(width: 240)
    .padding()
}
