import SwiftUI
import Testing
@testable import DesignSystem

/// Specification for `ZoneTone`, the five heart-rate zone colours.
@Suite("Zone tone")
struct ZoneToneTests {

    /// The backgrounds zone colours sit on: grouped list rows in light and dark mode.
    static let lightBackground = RGB.white
    static let darkBackground = RGB(hex: 0x1C1C1E)

    /// WCAG 2.1 minimum for large text (our 44pt zone number) and UI graphics (1.4.3, 1.4.11).
    static let minimumContrast = 3.0

    // MARK: - Lookup

    @Test("There is one tone per zone number, 1 to 5")
    func oneTonePerZone() {
        #expect(ZoneTone.allCases.map(\.rawValue) == [1, 2, 3, 4, 5])
    }

    @Test("Zone numbers outside 1...5 have no tone", arguments: [0, 6, -1])
    func noToneOutsideRange(number: Int) {
        #expect(ZoneTone(rawValue: number) == nil)
    }

    @Test("Every tone is a different colour, in light and in dark")
    func tonesAreDistinct() {
        #expect(Set(ZoneTone.allCases.map(\.light)).count == 5)
        #expect(Set(ZoneTone.allCases.map(\.dark)).count == 5)
    }

    // MARK: - Accessibility

    @Test("Light tones reach 3:1 against the light background", arguments: ZoneTone.allCases)
    func lightContrast(tone: ZoneTone) {
        let ratio = tone.light.contrastRatio(with: Self.lightBackground)

        #expect(ratio >= Self.minimumContrast, "Zone \(tone.rawValue) light is only \(ratio):1")
    }

    @Test("Dark tones reach 3:1 against the dark background", arguments: ZoneTone.allCases)
    func darkContrast(tone: ZoneTone) {
        let ratio = tone.dark.contrastRatio(with: Self.darkBackground)

        #expect(ratio >= Self.minimumContrast, "Zone \(tone.rawValue) dark is only \(ratio):1")
    }

    // MARK: - Adapting to appearance

    /// Test arguments run in parallel, so they must be `Sendable`; key paths need the `& Sendable`.
    typealias Variant = KeyPath<ZoneTone, RGB> & Sendable

    @Test("The zone shape style picks the variant for the colour scheme", arguments: [
        (ColorScheme.light, \ZoneTone.light as Variant),
        (ColorScheme.dark, \ZoneTone.dark as Variant)
    ])
    func resolvesForColorScheme(scheme: ColorScheme, variant: Variant) {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme

        for tone in ZoneTone.allCases {
            #expect(ZoneTint(tone).resolve(in: environment) == tone[keyPath: variant].color)
        }
    }
}
