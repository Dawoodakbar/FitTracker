import Foundation
import OSLog
import Domain
import Repositories
import Sensors
import HistoryFeature
import WorkoutFeature

/// The composition root: the only place in the app that creates concrete implementations
/// and hands them to features. Features only ever see Domain protocols.
///
/// To swap an implementation (e.g. a network repository later), change it here and nowhere else.
final class AppContainer {
    let workoutRepository: any WorkoutRepository
    let heartRateSource: any HeartRateSource
    let zoneCalculator: HeartRateZoneCalculator

    init(
        workoutRepository: any WorkoutRepository,
        heartRateSource: any HeartRateSource,
        zoneCalculator: HeartRateZoneCalculator
    ) {
        self.workoutRepository = workoutRepository
        self.heartRateSource = heartRateSource
        self.zoneCalculator = zoneCalculator
    }

    // MARK: - Configurations

    /// The real app: workouts saved to disk with Core Data.
    /// Heart rate is simulated until the Bluetooth step replaces it here.
    static func live() -> AppContainer {
        AppContainer(
            workoutRepository: makeDiskRepository(),
            heartRateSource: SimulatedHeartRateSource(),
            zoneCalculator: defaultZoneCalculator()
        )
    }

    /// Previews and tests: a real Core Data store that only lives in memory.
    static func inMemory() throws -> AppContainer {
        AppContainer(
            workoutRepository: try CoreDataWorkoutRepository.inMemory(),
            heartRateSource: SimulatedHeartRateSource(),
            zoneCalculator: defaultZoneCalculator()
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

    /// Until Settings exists, zones use the Fox formula for a 30-year-old (max 190 BPM).
    private static func defaultZoneCalculator() -> HeartRateZoneCalculator {
        do {
            return try HeartRateZoneCalculator(age: 30)
        } catch {
            // 30 is inside the valid range, so this can only fail if Domain's rules change.
            preconditionFailure("The default age must be valid: \(error)")
        }
    }
}
