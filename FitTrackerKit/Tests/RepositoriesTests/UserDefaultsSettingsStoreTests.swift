import Foundation
import Testing
import Domain
@testable import Repositories

/// The two behaviours that matter: settings survive a relaunch, and bad stored data can't
/// produce impossible zones.
@Suite("Settings store")
struct UserDefaultsSettingsStoreTests {

    /// A throwaway defaults domain, so tests never touch the real app settings.
    func makeDefaults() throws -> UserDefaults {
        let name = "FitTrackerTests.\(UUID().uuidString)"
        return try #require(UserDefaults(suiteName: name))
    }

    @Test("Saved settings are loaded back, and a new install gets the standard ones")
    func roundTrip() throws {
        let defaults = try makeDefaults()
        #expect(UserDefaultsSettingsStore(defaults: defaults).load() == .standard)

        let saved = try UserSettings(age: 45, formulaKind: .tanaka)
        UserDefaultsSettingsStore(defaults: defaults).save(saved)

        // A new store instance stands in for the next launch.
        #expect(UserDefaultsSettingsStore(defaults: defaults).load() == saved)
    }

    @Test("An invalid stored age falls back to the standard settings")
    func invalidStoredAge() throws {
        let defaults = try makeDefaults()
        defaults.set(0, forKey: "settings.age")
        defaults.set("fox", forKey: "settings.formula")

        #expect(UserDefaultsSettingsStore(defaults: defaults).load() == .standard)
    }
}
