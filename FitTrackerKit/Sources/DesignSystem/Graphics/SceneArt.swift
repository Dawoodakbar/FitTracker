import SwiftUI

/// Original generative artwork for cards: a glowing sky, a sun or moon, and layered hills or
/// waves, all in one colour family. Each `seed` gives a different, repeatable landscape, so
/// every plan gets its own picture without any image files.
public struct SceneArt: View {
    public enum Kind: Sendable {
        /// Rolling hills under a low sun. For strength, running and everyday cards.
        case hills
        /// Soft waves under a rising sun. For yoga, mobility and calm cards.
        case waves
        /// Mountains under a moon and stars. For sleep and evening cards.
        case night
        /// Bright layered peaks. For intense training like HIIT.
        case peaks
    }

    let style: RingStyle
    let kind: Kind
    let seed: Int

    public init(style: RingStyle, kind: Kind, seed: Int = 0) {
        self.style = style
        self.kind = kind
        self.seed = seed
    }

    /// A stable seed from a string, the same on every launch (unlike `Hasher`).
    public static func seed(for text: String) -> Int {
        text.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0x7FFF_FFFF }
    }

    public var body: some View {
        Canvas { context, size in
            drawSky(in: &context, size: size)
            if kind == .night { drawStars(in: &context, size: size) }
            drawOrb(in: &context, size: size)
            drawLayers(in: &context, size: size)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Drawing

    private func drawSky(in context: inout GraphicsContext, size: CGSize) {
        let top = kind == .night ? Palette.night : style.start.mix(with: Palette.night, by: 0.55)
        let bottom = kind == .night ? style.start.mix(with: Palette.night, by: 0.5) : style.end.mix(with: Palette.dusk, by: 0.25)
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(Gradient(colors: [top, bottom]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize) {
        for index in 0..<24 {
            let x = noise(index, 1) * size.width
            let y = noise(index, 2) * size.height * 0.55
            let r = 0.6 + noise(index, 3) * 1.4
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.35 + 0.5 * noise(index, 4))))
        }
    }

    /// The sun or moon, with a wide blurred halo.
    private func drawOrb(in context: inout GraphicsContext, size: CGSize) {
        let radius = size.height * (kind == .night ? 0.13 : 0.17)
        let center = CGPoint(x: size.width * (0.2 + 0.6 * noise(seed, 5)), y: size.height * (0.28 + 0.12 * noise(seed, 6)))
        let color = kind == .night ? Palette.ice : Palette.honey.mix(with: style.end, by: 0.35)

        var halo = context
        halo.addFilter(.blur(radius: radius * 1.2))
        halo.fill(Path(ellipseIn: CGRect(x: center.x - radius * 2, y: center.y - radius * 2, width: radius * 4, height: radius * 4)), with: .color(color.opacity(0.45)))

        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        if kind == .night {
            // A crescent: subtract an offset circle from the moon's shape itself, so the sky
            // behind stays untouched (erasing pixels would punch a hole through the sky too).
            let offset = radius * 0.45
            let bite = Path(ellipseIn: CGRect(x: center.x - radius + offset, y: center.y - radius - offset * 0.4, width: radius * 2, height: radius * 2))
            context.fill(disc.subtracting(bite), with: .color(color))
        } else {
            context.fill(disc, with: .color(color))
        }
    }

    /// Three overlapping ridges, darker towards the front, for depth.
    private func drawLayers(in context: inout GraphicsContext, size: CGSize) {
        for layer in 0..<3 {
            let depth = Double(layer) / 2
            let baseline = size.height * (0.55 + 0.15 * depth)
            let amplitude = size.height * (kind == .peaks ? 0.22 : kind == .waves ? 0.06 : 0.11) * (1 - 0.3 * depth)
            let waves = kind == .waves ? 2.5 : kind == .peaks ? 3.0 : 1.6
            let phase = noise(seed, 10 + layer) * 2 * .pi

            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))
            let steps = 48
            for step in 0...steps {
                let x = size.width * CGFloat(step) / CGFloat(steps)
                let progress = Double(step) / Double(steps)
                var wave = sin(progress * waves * 2 * .pi + phase)
                if kind == .peaks { wave = 1 - abs(wave) * 2 }  // sharp ridges instead of rounded ones
                path.addLine(to: CGPoint(x: x, y: baseline - amplitude * wave))
            }
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()

            let front = style.start.mix(with: Palette.night, by: 0.35 + 0.4 * depth)
            let back = style.end.mix(with: Palette.night, by: 0.15 + 0.4 * depth)
            context.fill(path, with: .linearGradient(
                Gradient(colors: [back, front]),
                startPoint: CGPoint(x: 0, y: baseline - amplitude),
                endPoint: CGPoint(x: 0, y: size.height)
            ))
        }
    }

    /// Repeatable "random" numbers in 0...1.
    private func noise(_ index: Int, _ salt: Int) -> Double {
        let value = sin(Double(index &+ seed &* 3) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return value - value.rounded(.down)
    }
}

#Preview {
    VStack {
        SceneArt(style: .move, kind: .hills, seed: 1)
        SceneArt(style: .prayer, kind: .waves, seed: 2)
        SceneArt(style: .sleep, kind: .night, seed: 3)
        SceneArt(style: .plan, kind: .peaks, seed: 4)
    }
    .frame(height: 600)
}
