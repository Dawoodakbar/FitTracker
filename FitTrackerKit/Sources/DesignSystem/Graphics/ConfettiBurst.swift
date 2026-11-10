import SwiftUI

/// A one-off burst of confetti, for finishing a session or completing a day.
///
/// Every particle's path is a pure function of its index and the time since `startDate`,
/// so there is no particle state to store: the canvas just redraws each frame.
public struct ConfettiBurst: View {
    static let duration = 2.4
    static let colors: [Color] = [.pink, .orange, .yellow, .green, .mint, .blue, .purple]

    let startDate: Date
    let particleCount: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(startDate: Date, particleCount: Int = 70) {
        self.startDate = startDate
        self.particleCount = particleCount
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            Canvas { context, size in
                guard !reduceMotion, elapsed >= 0, elapsed < Self.duration else { return }
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.35)

                for index in 0..<particleCount {
                    // Cheap repeatable "random" numbers in 0...1 from the particle's index.
                    let a = Self.noise(index, 1), b = Self.noise(index, 2), c = Self.noise(index, 3)
                    let angle = a * 2 * .pi
                    let speed = 140 + 260 * b
                    let x = origin.x + cos(angle) * speed * elapsed
                    // Launch upwards, then gravity pulls the piece down.
                    let y = origin.y + sin(angle) * speed * elapsed * 0.6 - 120 * elapsed + 420 * elapsed * elapsed

                    var piece = context
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(elapsed * (4 + 6 * c) + a * 6))
                    piece.opacity = 1 - elapsed / Self.duration
                    let rect = CGRect(x: -4, y: -2.5, width: 8 + 4 * c, height: 5)
                    piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(Self.colors[index % Self.colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func noise(_ index: Int, _ salt: Int) -> Double {
        let value = sin(Double(index) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return value - value.rounded(.down)
    }
}

#Preview {
    ConfettiBurst(startDate: .now)
}
