import SwiftUI

extension View {
    /// The standard content card: frosted glass over the night background, with large soft
    /// corners and a hairline border so it reads as a layer without heavy shadows.
    public func card(padding: CGFloat = Spacing.m) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Palette.surface)
                    .background(.ultraThinMaterial.opacity(0.35), in: .rect(cornerRadius: 26, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(Palette.surfaceBorder, lineWidth: 1)
                    }
            }
    }
}
