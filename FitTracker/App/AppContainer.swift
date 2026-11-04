import Foundation
import OSLog
import Domain
import Repositories
import Sensors
import HistoryFeature
import SettingsFeature
import WorkoutFeature

/// The composition root: the only place in the app that creates concrete implementations
/// and hands them to features. Features only ever see Domain protocols.
///
/// To swap an implementation (e.g. a network repository later), change it here and nowhere else.
final class AppContainer {
    let workoutRepository: any WorkoutRepository
    let heartRateSource: any HeartRateSource
    /// Shared by the Settings screen and every feature that needs the user's zones.
    let settingsViewModel: SettingsViewModel

    /// The user's current zones, from their settings.
    var zoneCalculator: HeartRateZoneCalculator { settingsViewModel.settings.calculator }

    init(
        workoutRepository: any WorkoutRepository,
        heartRateSource: any HeartRateSource,
        settingsStore: any SettingsStore
    ) {
        self.workoutRepository = workoutRepository
        self.heartRateSource = heartRateSource
        self.settingsViewModel = SettingsViewModel(store: settingsStore)
    }

    // MARK: - Configurations

    /// The real app: workouts saved to disk with Core Data, settings in UserDefaults.
    /// Heart rate comes from a Bluetooth monitor on a real device. The simulator has no
    /// Bluetooth, so it uses the simulated source.
    static func live() -> AppContainer {
        #if targetEnvironment(simulator)
        let source: any HeartRateSource = SimulatedHeartRateSource()
        #else
        let source: any HeartRateSource = BluetoothHeartRateSource()
        #endif
        return AppContainer(
            workoutRepository: makeDiskRepository(),
            heartRateSource: source,
            settingsStore: UserDefaultsSettingsStore()
        )
    }

    /// Previews and tests: a real Core Data store that only lives in memory, and settings that
    /// are saved in a throwaway defaults domain so previews never change the real ones.
    static func inMemory() throws -> AppContainer {
        AppContainer(
            workoutRepository: try CoreDataWorkoutRepository.inMemory(),
            heartRateSource: SimulatedHeartRateSource(),
            settingsStore: UserDefaultsSettingsStore(defaults: UserDefaults(suiteName: "FitTracker.preview") ?? .standard)
        )
    }

    // MARK: - Feature factories

    func makeHistoryViewModel() -> WorkoutHistoryViewModel {
        WorkoutHistoryViewModel(repository: workoutRepository, calculator: zoneCalculator)
    }

    func makeLiveWorkoutViewModel() -> LiveWorkoutViewModel {
        LiveWorkoutViewModel(source: heartRateSource, repository: workoutRepository, calculator: zoneCalculator)
    }

    // MARK: - Private

    private static let logger = Logger(subsystem: "com.dawoodakbar.FitTracker", category: "AppContainer")

    /// Opens the on-disk store. If that fails (disk full, corrupt file), the app still launches
    /// with an in-memory store instead of crashing, and the failure is logged.
    private static func makeDiskRepository() -> any WorkoutRepository {
        let url = CoreDataWorkoutRepository.defaultStoreURL()
        do {
            return try CoreDataWorkoutRepository(storeURL: url)
        } catch {
            logger.error("Couldn't open workout store at \(url.path(), privacy: .public): \(error)")
            do {
                return try CoreDataWorkoutRepository.inMemory()
            } catch {
                // An in-memory SQLite store needs no disk access; failing here means Core Data
                // itself is broken, and there is nothing useful the app can do.
                fatalError("Couldn't create an in-memory workout store: \(error)")
            }
        }
    }
}
