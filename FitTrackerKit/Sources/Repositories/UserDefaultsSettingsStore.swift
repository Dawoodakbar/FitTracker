import Foundation
import Domain

/// Saves `UserSettings` in `UserDefaults`.
///
/// `@unchecked Sendable` because `UserDefaults` is documented as thread-safe but isn't
/// marked `Sendable` in every SDK; this class has no other mutable state.
public final class UserDefaultsSettingsStore: SettingsStore, @unchecked Sendable {
    private enum Key {
        static let age = "settings.age"
        static let formula = "settings.formula"
    }

    private let defaults: UserDefaults

    /// - Parameter defaults: Tests pass a throwaway suite so they never touch the real settings.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> UserSettings {
        // Anything missing or invalid (an old version's value, a hand-edited plist) falls back to
        // the standard settings rather than crashing or producing impossible zones.
        guard
            let age = defaults.object(forKey: Key.age) as? Int,
            let rawFormula = defaults.string(forKey: Key.formula),
            let kind = MaxHeartRateFormulaKind(rawValue: rawFormula),
            let settings = try? UserSettings(age: age, formulaKind: kind)
        else {
            return .standard
        }
        return settings
    }

    public func save(_ settings: UserSettings) {
        defaults.set(settings.age, forKey: Key.age)
        defaults.set(settings.formulaKind.rawValue, forKey: Key.formula)
    }
}
