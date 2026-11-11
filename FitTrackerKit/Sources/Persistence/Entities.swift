import CoreData

/// A stored workout. Only used inside `perform` blocks of the context that fetched it;
/// managed objects are not thread-safe and never leave the Persistence/Repositories layers.
@objc(WorkoutEntity)
public final class WorkoutEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    /// Deleting a workout deletes its samples too (cascade rule in `WorkoutStore.model`).
    @NSManaged public var samples: Set<HeartRateSampleEntity>
}

/// A stored heart-rate reading, owned by one `WorkoutEntity`.
@objc(HeartRateSampleEntity)
public final class HeartRateSampleEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var bpm: Int64
    @NSManaged public var date: Date
    @NSManaged public var workout: WorkoutEntity?
}

extension WorkoutEntity {
    /// A typed fetch request; Core Data's generic one returns `NSFetchRequestResult`.
    public static func fetchRequest(id: UUID? = nil) -> NSFetchRequest<WorkoutEntity> {
        let request = NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
        if let id {
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
        }
        return request
    }
}
