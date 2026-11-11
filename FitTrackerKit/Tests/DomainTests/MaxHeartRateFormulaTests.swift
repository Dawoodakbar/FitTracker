import Testing
@testable import Domain

/// Specification for `MaxHeartRateFormula` strategies and how `HeartRateZoneCalculator` uses them.
///
/// | Formula | Max heart rate         | Rounding           |
/// | ------- | ---------------------- | ------------------ |
/// | Fox     | 220 - age              | exact              |
/// | Tanaka  | 208 - 0.7 × age        | .5 rounds up       |
@Suite("Max heart rate formula")
struct MaxHeartRateFormulaTests {

    // MARK: - Formulas

    @Test("Fox formula is 220 - age", arguments: [(20, 200), (30, 190), (40, 180)])
    func fox(age: Int, expected: Int) {
        #expect(FoxFormula().maxHeartRate(forAge: age) == expected)
    }

    @Test("Tanaka formula is 208 - 0.7 × age, rounding .5 up", arguments: [
        (20, 194),   // 208 - 14.0
        (30, 187),   // 208 - 21.0
        (40, 180),   // 208 - 28.0
        (25, 191),   // 208 - 17.5 = 190.5 -> 191
        (35, 184)    // 208 - 24.5 = 183.5 -> 184
    ])
    func tanaka(age: Int, expected: Int) {
        #expect(TanakaFormula().maxHeartRate(forAge: age) == expected)
    }

    @Test("Formulas can be written with dot syntax")
    func dotSyntax() {
        // `.fox` / `.tanaka` resolve through static members on the protocol.
        let formulas: [any MaxHeartRateFormula] = [.fox, .tanaka]

        #expect(formulas.map { $0.maxHeartRate(forAge: 40) } == [180, 180])
    }

    // MARK: - Calculator integration

    @Test("Calculator uses the Fox formula by default")
    func calculatorDefaultsToFox() throws {
        let calculator = try HeartRateZoneCalculator(age: 25)

        #expect(calculator.maxHeartRate == 195)
    }

    @Test("Calculator uses the formula it is given")
    func calculatorUsesGivenFormula() throws {
        let calculator = try HeartRateZoneCalculator(age: 25, formula: .tanaka)

        #expect(calculator.maxHeartRate == 191)
    }

    @Test("Calculator still rejects invalid ages with any formula", arguments: [0, 121])
    func calculatorRejectsInvalidAgeWithFormula(age: Int) {
        #expect(throws: HeartRateZoneError.invalidAge) {
            try HeartRateZoneCalculator(age: age, formula: .tanaka)
        }
    }

    @Test("Calculator rejects a formula that produces an invalid max heart rate")
    func calculatorRejectsInvalidFormulaResult() {
        #expect(throws: HeartRateZoneError.invalidMaxHeartRate) {
            try HeartRateZoneCalculator(age: 30, formula: StubFormula(result: 0))
        }
    }
}

/// A test **stub**: returns a canned value so we can test how the calculator handles
/// results no real formula would produce.
private struct StubFormula: MaxHeartRateFormula {
    let result: Int

    func maxHeartRate(forAge age: Int) -> Int { result }
}
