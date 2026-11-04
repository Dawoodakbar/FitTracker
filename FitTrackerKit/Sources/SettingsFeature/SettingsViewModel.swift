import Observation
import Domain

/// The state behind the Settings screen. Every valid change is saved immediately.
@MainActor
@Observable
public final class SettingsViewModel {
    /// The current settings. Other screens read `settings.calculator` to get the user's zones.
    public private(set) var settings: UserSettings

    private let store: any SettingsStore

    public init(store: any SettingsStore) {
        self.store = store
        self.settings = store.load()
    }

    public var age: Int {
        get { settings.age }
        set { update(age: newValue, formulaKind: settings.formulaKind) }
    }

    public var formulaKind: MaxHeartRateFormulaKind {
        get { settings.formulaKind }
        set { update(age: settings.age, formulaKind: newValue) }
    }

    private func update(age: Int, formulaKind: MaxHeartRateFormulaKind) {
        // An invalid age is ignored: the previous valid settings stay in place.
        guard let updated = try? UserSettings(age: age, formulaKind: formulaKind), updated != settings else { return }
        settings = updated
        store.save(updated)
    }
}
