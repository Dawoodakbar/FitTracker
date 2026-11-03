import CoreData

/// The Core Data stack for workouts: the data model and a loaded persistent container.
public final class WorkoutStore: Sendable {
    // `NSPersistentContainer` is thread-safe to *hold*; all work happens inside contexts'
    // `perform` blocks, which Core Data runs on each context's own queue.
    public let container: NSPersistentContainer

    /// - Parameter storeURL: Where the SQLite file lives, or `nil` for a throwaway in-memory
    ///   store (tests and previews).
    public init(storeURL: URL?) throws {
        if let storeURL {
            // Core Data doesn't create missing folders. Application Support doesn't exist on a
            // fresh install, so create it first instead of relying on Core Data's noisy recovery.
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }
        container = NSPersistentContainer(name: "Workouts", managedObjectModel: Self.model)

        let description = NSPersistentStoreDescription()
        // `/dev/null` gives a real SQLite store that's never written to disk: same behaviour
        // as production (unlike `NSInMemoryStoreType`), but nothing left behind.
        description.url = storeURL ?? URL(filePath: "/dev/null")
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        // With `shouldAddStoreAsynchronously = false` this callback runs before returning.
        nonisolated(unsafe) var loadError: (any Error)?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
    }

    /// A new context that works on a private background queue.
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        // If two saves touch the same object, the one saving last wins.
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }

    // MARK: - Model

    /// The data model, built in code. Created once: Core Data warns if several models
    /// claim the same entity classes.
    ///
    /// `nonisolated(unsafe)`: `NSManagedObjectModel` isn't marked `Sendable`, but it's fully
    /// built inside this initializer and never modified afterwards (Core Data makes a model
    /// immutable once a coordinator uses it), so sharing it across threads is safe.
    nonisolated(unsafe) static let model: NSManagedObjectModel = {
        let workout = NSEntityDescription()
        workout.name = "WorkoutEntity"
        workout.managedObjectClassName = NSStringFromClass(WorkoutEntity.self)

        let sample = NSEntityDescription()
        sample.name = "HeartRateSampleEntity"
        sample.managedObjectClassName = NSStringFromClass(HeartRateSampleEntity.self)

        let samples = NSRelationshipDescription()
        samples.name = "samples"
        samples.destinationEntity = sample
        samples.minCount = 0
        samples.maxCount = 0              // 0 = unlimited, which makes it to-many
        samples.deleteRule = .cascadeDeleteRule

        let owner = NSRelationshipDescription()
        owner.name = "workout"
        owner.destinationEntity = workout
        owner.maxCount = 1                // to-one
        owner.isOptional = true
        owner.deleteRule = .nullifyDeleteRule

        samples.inverseRelationship = owner
        owner.inverseRelationship = samples

        let workoutID = attribute("id", .UUIDAttributeType)
        workout.properties = [
            workoutID,
            attribute("startDate", .dateAttributeType),
            attribute("endDate", .dateAttributeType),
            samples
        ]
        sample.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("bpm", .integer64AttributeType),
            attribute("date", .dateAttributeType),
            owner
        ]
        // Indexed, because every save and delete looks a workout up by id.
        workout.indexes = [
            NSFetchIndexDescription(
                name: "byID",
                elements: [NSFetchIndexElementDescription(property: workoutID, collationType: .binary)]
            )
        ]

        let model = NSManagedObjectModel()
        model.entities = [workout, sample]
        return model
    }()

    private static func attribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = false
        return attribute
    }
}
