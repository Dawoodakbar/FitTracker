import SwiftUI

/// A 24-hour clock face with the night drawn as a glowing arc from bedtime to wake time.
///
/// Midnight is at the top and time runs clockwise. The arc is drawn with Core Graphics
/// (a stroked path used as a clip for a gradient) and sweeps in when the dial appears.
public struct SleepDial: View {
    let bedMinutes: Int?
    let wakeMinutes: Int?

    @State private var reveal: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters: Clock times as minutes after midnight (0..<1440), or `nil` for an empty dial.
    public init(bedMinutes: Int?, wakeMinutes: Int?) {
        self.bedMinutes = bedMinutes
        self.wakeMinutes = wakeMinutes
        self.reveal = 0
    }

    public var body: some View {
        DialCanvas(bedMinutes: bedMinutes, wakeMinutes: wakeMinutes, reveal: reveal)
            .aspectRatio(1, contentMode: .fit)
            .onAppear { animate() }
            .onChange(of: [bedMinutes, wakeMinutes]) { _, _ in
                reveal = 0
                animate()
            }
            .accessibilityHidden(true)
    }

    private func animate() {
        if reduceMotion {
            reveal = 1
        } else {
            withAnimation(.easeOut(duration: 1.1)) { reveal = 1 }
        }
    }
}

/// The drawing itself. `Animatable`, so SwiftUI redraws the canvas for every frame of `reveal`.
private struct DialCanvas: View, Animatable {
    let bedMinutes: Int?
    let wakeMinutes: Int?
    var reveal: Double

    var animatableData: Double {
        get { reveal }
        set { reveal = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let lineWidth = size.width * 0.085
            let radius = size.width / 2 - lineWidth / 2 - 2

            drawTrack(in: &context, center: center, radius: radius, lineWidth: lineWidth)
            drawTicks(in: &context, center: center, radius: radius - lineWidth / 2 - 6)
            if let bedMinutes, let wakeMinutes {
                drawNight(
                    in: &context, center: center, radius: radius, lineWidth: lineWidth,
                    bedMinutes: bedMinutes, wakeMinutes: wakeMinutes
                )
            }
        }
    }

    private func drawTrack(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let track = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.stroke(track, with: .color(RingStyle.sleep.start.opacity(0.15)), lineWidth: lineWidth)
    }

    /// A tick per hour, longer every six hours, with 0 / 6 / 12 / 18 labels inside.
    private func drawTicks(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        for hour in 0..<24 {
            let angle = Self.angle(forMinutes: hour * 60)
            let isMajor = hour % 6 == 0
            let length: CGFloat = isMajor ? 9 : 4
            var tick = Path()
            tick.move(to: Self.point(center: center, radius: radius, angle: angle))
            tick.addLine(to: Self.point(center: center, radius: radius - length, angle: angle))
            context.stroke(tick, with: .color(.secondary.opacity(isMajor ? 0.9 : 0.4)), lineWidth: isMajor ? 2 : 1)

            if isMajor {
                let label = Text(verbatim: "\(hour)").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                context.draw(label, at: Self.point(center: center, radius: radius - 22, angle: angle))
            }
        }
    }

    private func drawNight(
        in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat,
        bedMinutes: Int, wakeMinutes: Int
    ) {
        let start = Self.angle(forMinutes: bedMinutes)
        // A night that crosses midnight wraps round the dial.
        let asleep = (wakeMinutes - bedMinutes + 1440) % 1440
        let sweep = CGFloat(asleep) / 1440 * 2 * .pi * reveal
        guard sweep > 0.001 else { return }

        let startColor = RingStyle.sleep.start.resolve(in: context.environment).cgColor
        let endColor = RingStyle.sleep.end.resolve(in: context.environment).cgColor

        // Core Graphics: stroke the arc into a shape, clip to it, and fill the clip with a gradient.
        // The canvas's y axis points down, so increasing angles run clockwise on screen.
        context.withCGContext { cg in
            cg.saveGState()
            cg.setShadow(offset: .zero, blur: lineWidth * 0.6, color: endColor.copy(alpha: 0.6))
            cg.setStrokeColor(endColor)
            cg.setLineWidth(lineWidth)
            cg.setLineCap(.round)
            cg.addArc(center: center, radius: radius, startAngle: start, endAngle: start + sweep, clockwise: false)
            cg.strokePath()
            cg.restoreGState()

            cg.saveGState()
            cg.setLineWidth(lineWidth)
            cg.setLineCap(.round)
            cg.addArc(center: center, radius: radius, startAngle: start, endAngle: start + sweep, clockwise: false)
            cg.replacePathWithStrokedPath()
            cg.clip()
            if let gradient = CGGradient(
                colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                colors: [startColor, endColor] as CFArray,
                locations: [0, 1]
            ) {
                cg.drawLinearGradient(
                    gradient,
                    start: Self.point(center: center, radius: radius, angle: start),
                    end: Self.point(center: center, radius: radius, angle: start + sweep),
                    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
                )
            }
            cg.restoreGState()
        }

        // Moon where the night starts, sun where it ends (once the sweep has arrived).
        let symbolFont = Font.system(size: lineWidth * 0.55, weight: .bold)
        context.draw(
            Text(Image(systemName: "moon.fill")).font(symbolFont).foregroundStyle(.white),
            at: Self.point(center: center, radius: radius, angle: start)
        )
        if reveal > 0.98 {
            context.draw(
                Text(Image(systemName: "sun.max.fill")).font(symbolFont).foregroundStyle(.white),
                at: Self.point(center: center, radius: radius, angle: start + sweep)
            )
        }
    }

    /// Midnight at the top (−90°), 24 hours for a full turn.
    static func angle(forMinutes minutes: Int) -> CGFloat {
        CGFloat(minutes) / 1440 * 2 * .pi - .pi / 2
    }

    static func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}

#Preview("23:15 to 06:45") {
    SleepDial(bedMinutes: 23 * 60 + 15, wakeMinutes: 6 * 60 + 45)
        .frame(width: 260)
        .padding()
}
