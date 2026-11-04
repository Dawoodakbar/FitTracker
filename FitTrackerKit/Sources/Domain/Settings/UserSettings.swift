/// The max-heart-rate formulas a user can choose between. Raw values are stored on disk,
/// so never rename or reorder them.
public enum MaxHeartRateFormulaKind: String, CaseIterable, Identifiable, Sendable {
    case fox
    case tanaka

    public var id: Self { self }

    var formula: any MaxHeartRateFormula {
        switch self {
        case .fox: FoxFormula()
        case .tanaka: TanakaFormula()
        }
    }
}

/// The personal details that define a user's heart-rate zones.
///
/// An instance is always valid: the initializer rejects ages the calculator can't use,
/// so everything holding one can rely on `calculator` without checking.
public struct UserSettings: Equatable, Sendable {
    public let age: Int
    public let formulaKind: MaxHeartRateFormulaKind
    /// The zones that follow from `age` and `formulaKind`.
    public let calculator: HeartRateZoneCalculator

    /// - Throws: `HeartRateZoneError` if the age (or the formula's result) is invalid.
    public init(age: Int, formulaKind: MaxHeartRateFormulaKind) throws(HeartRateZoneError) {
        self.age = age
        self.formulaKind = formulaKind
        self.calculator = try HeartRateZoneCalculator(age: age, formula: formulaKind.formula)
    }

    /// What a new install starts with: 30 years old, Fox formula.
    public static let standard: UserSettings = {
        do {
            return try UserSettings(age: 30, formulaKind: .fox)
        } catch {
            preconditionFailure("The standard settings must be valid: \(error)")
        }
    }()
}

/// Remembers the user's settings between launches.
public protocol SettingsStore: Sendable {
    /// The saved settings, or `UserSettings.standard` if none are saved or the saved ones are unusable.
    func load() -> UserSettings
    func save(_ settings: UserSettings)
}
