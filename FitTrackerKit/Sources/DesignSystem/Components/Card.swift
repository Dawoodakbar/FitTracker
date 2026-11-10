import SwiftUI

extension View {
    /// The standard content card: padded, on a secondary background with large corners.
    public func card() -> some View {
        padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: .rect(cornerRadius: 22))
    }
}
