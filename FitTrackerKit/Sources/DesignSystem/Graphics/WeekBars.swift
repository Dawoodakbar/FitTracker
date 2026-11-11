import SwiftUI

/// A small bar chart, one bar per day, with an optional dashed goal line. Bars grow from the
/// baseline when the chart appears.
public struct WeekBars: View {
    public struct Bar: Identifiable, Equatable, Sendable {
        public let id: Int
        public let label: String
        public let value: Double
        public let isHighlighted: Bool

        public init(id: Int, label: String, value: Double, isHighlighted: Bool = false) {
            self.id = id
            self.label = label
            self.value = value
            self.isHighlighted = isHighlighted
        }
    }

    let bars: [Bar]
    let goal: Double?
    let style: RingStyle

    @State private var grow: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(bars: [Bar], goal: Double? = nil, style: RingStyle) {
        self.bars = bars
        self.goal = goal
        self.style = style
        self.grow = 0
    }

    public var body: some View {
        BarsCanvas(bars: bars, goal: goal, style: style, grow: grow)
            .onAppear {
                if reduceMotion {
                    grow = 1
                } else {
                    withAnimation(.spring(duration: 0.8, bounce: 0.25)) { grow = 1 }
                }
            }
            .accessibilityHidden(true)
    }
}

private struct BarsCanvas: View, Animatable {
    let bars: [WeekBars.Bar]
    let goal: Double?
    let style: RingStyle
    var grow: Double

    var animatableData: Double {
        get { grow }
        set { grow = newValue }
    }

    var body: some View {
        Canvas { context, size in
            guard !bars.isEmpty else { return }
            let labelHeight: CGFloat = 18
            let chartHeight = size.height - labelHeight
            // Leave headroom above the tallest bar or the goal, whichever is higher.
            let top = max(bars.map(\.value).max() ?? 0, goal ?? 0, 0.001) * 1.1
            let slot = size.width / CGFloat(bars.count)
            let barWidth = min(slot * 0.55, 28)

            for (index, bar) in bars.enumerated() {
                let x = slot * (CGFloat(index) + 0.5)
                let height = max(CGFloat(bar.value / top) * chartHeight * grow, bar.value > 0 ? 4 : 0)
                let rect = CGRect(x: x - barWidth / 2, y: chartHeight - height, width: barWidth, height: height)
                let shape = Path(roundedRect: rect, cornerRadius: barWidth / 3)
                let shading = GraphicsContext.Shading.linearGradient(
                    Gradient(colors: [style.end, style.start]),
                    startPoint: CGPoint(x: x, y: rect.minY),
                    endPoint: CGPoint(x: x, y: chartHeight)
                )
                context.opacity = bar.isHighlighted ? 1 : 0.55
                context.fill(shape, with: shading)
                context.opacity = 1

                let label = Text(bar.label)
                    .font(.caption2.weight(bar.isHighlighted ? .bold : .regular))
                    .foregroundStyle(bar.isHighlighted ? .primary : .secondary)
                context.draw(label, at: CGPoint(x: x, y: size.height - labelHeight / 2 + 2))
            }

            if let goal {
                let y = chartHeight - CGFloat(goal / top) * chartHeight
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(line, with: .color(.secondary.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
    }
}

#Preview {
    WeekBars(
        bars: [6.5, 7.2, 5.8, 8.1, 7.4, 0, 7.9].enumerated().map {
            .init(id: $0.offset, label: ["M", "T", "W", "T", "F", "S", "S"][$0.offset], value: $0.element, isHighlighted: $0.offset == 6)
        },
        goal: 8,
        style: .sleep
    )
    .frame(height: 160)
    .padding()
}
