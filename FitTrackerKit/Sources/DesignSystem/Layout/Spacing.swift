import CoreGraphics

/// The spacing scale for padding and stack spacing, on a 4-point grid.
///
/// Use these instead of literal numbers so spacing stays consistent across screens and can
/// be tuned in one place: `VStack(spacing: Spacing.xs)`, `.padding(Spacing.m)`.
public enum Spacing {
    /// 4pt: between tightly related lines, like a title and its subtitle.
    public static let xs: CGFloat = 4
    /// 8pt: between items inside one row.
    public static let s: CGFloat = 8
    /// 16pt: between distinct elements, and standard content padding.
    public static let m: CGFloat = 16
    /// 24pt: between groups.
    public static let l: CGFloat = 24
    /// 32pt: between major sections.
    public static let xl: CGFloat = 32
}
