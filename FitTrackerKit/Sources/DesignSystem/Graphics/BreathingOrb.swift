import SwiftUI

/// A soft orb that swells and shrinks on a slow breathing rhythm: four seconds in, four out.
/// Shown during rests and yoga holds to pace the user's breath.
public struct BreathingOrb: View {
    /// One full breath, in seconds.
    static let period = 8.0

    let style: RingStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(style: RingStyle) {
        self.style = style
    }

    public var body: some View {
        // `paused` stops the timeline entirely when the user prefers reduced motion.
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let seconds = timeline.date.timeIntervalSinceReferenceDate
            // 0 (fully out) ... 1 (fully in), easing at both ends like a real breath.
            let breath = reduceMotion ? 0.6 : (1 - cos(seconds / Self.period * 2 * .pi)) / 2

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = min(size.width, size.height) / 2

                // Blurred layers from the outside in: each a little smaller and more solid.
                for layer in 0..<4 {
                    let depth = CGFloat(layer) / 3
                    let radius = maxRadius * (0.45 + 0.5 * breath) * (1 - depth * 0.28)
                    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                    var layerContext = context
                    layerContext.addFilter(.blur(radius: maxRadius * 0.12 * (1 - depth)))
                    layerContext.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [style.end.opacity(0.35 + 0.2 * depth), style.start.opacity(0.2 + 0.25 * depth)]),
                            center: center, startRadius: 0, endRadius: radius
                        )
                    )
                }
            }
            .overlay {
                // The orb grows while sin(phase) is positive: that half of the cycle is the in-breath.
                Text(sin(seconds / Self.period * 2 * .pi) > 0 ? "Breathe in" : "Breathe out")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .opacity(reduceMotion ? 0 : 0.9)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    BreathingOrb(style: .prayer)
        .frame(width: 240)
        .padding()
}
