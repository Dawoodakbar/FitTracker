import SwiftUI

/// The night sky behind every screen: a deep indigo gradient with slow, drifting glows in the
/// screen's own colours. Motion is very slow (a full drift takes about 20 seconds) so it
/// feels alive without pulling attention, and it stops entirely with Reduce Motion.
public struct CalmBackground: View {
    let style: RingStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(style: RingStyle) {
        self.style = style
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate / 20 * 2 * .pi
            Canvas { context, size in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: [Palette.dusk, Palette.night, Palette.night]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
                // Two big soft glows drifting on slow ellipses.
                glow(in: &context, size: size, color: style.start,
                     center: CGPoint(x: size.width * (0.2 + 0.08 * cos(t)), y: size.height * (0.08 + 0.04 * sin(t))),
                     radius: size.width * 0.75, opacity: 0.32)
                glow(in: &context, size: size, color: style.end,
                     center: CGPoint(x: size.width * (0.95 + 0.06 * sin(t * 0.8)), y: size.height * (0.3 + 0.05 * cos(t * 0.8))),
                     radius: size.width * 0.6, opacity: 0.2)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func glow(in context: inout GraphicsContext, size: CGSize, color: Color, center: CGPoint, radius: CGFloat, opacity: Double) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [color.opacity(opacity), color.opacity(0)]),
                center: center, startRadius: 0, endRadius: radius
            )
        )
    }
}

extension View {
    /// Puts the calm night background behind this screen, tinted with `style`, and hides the
    /// default list and form backgrounds so it shows through.
    public func calmBackground(_ style: RingStyle) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background { CalmBackground(style: style) }
    }
}

#Preview {
    CalmBackground(style: .sleep)
}
