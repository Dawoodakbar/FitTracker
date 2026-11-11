import Testing
@testable import DesignSystem

/// Specification for `RGB` and the WCAG 2.x contrast ratio.
/// Reference values: https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
@Suite("RGB colour")
struct RGBTests {

    @Test("Reads components from a 0xRRGGBB hex value")
    func readsHex() {
        let color = RGB(hex: 0x4C82E6)

        #expect(color.red == 0x4C)
        #expect(color.green == 0x82)
        #expect(color.blue == 0xE6)
    }

    @Test("Black on white is the maximum contrast, 21:1")
    func blackOnWhite() {
        #expect(RGB.black.contrastRatio(with: .white) == 21)
    }

    @Test("A colour against itself has no contrast, 1:1")
    func sameColor() {
        let gray = RGB(hex: 0x808080)

        #expect(gray.contrastRatio(with: gray) == 1)
    }

    @Test("Contrast is the same in either direction")
    func symmetric() {
        let blue = RGB(hex: 0x4C82E6)

        #expect(blue.contrastRatio(with: .white) == RGB.white.contrastRatio(with: blue))
    }

    @Test("#767676 on white is about 4.54:1, the darkest gray that passes AA for body text")
    func knownGray() {
        let ratio = RGB(hex: 0x767676).contrastRatio(with: .white)

        #expect(abs(ratio - 4.54) < 0.01)
    }
}
