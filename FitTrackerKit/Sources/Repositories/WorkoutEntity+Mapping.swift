import CoreData
import Domain
import Persistence

// Mapping between Core Data entities and Domain values (the Adapter pattern).
// Must be called inside the owning context's `perform` block.

extension WorkoutEntity {
    /// Copies `workout` into this entity, replacing all of its samples.
    func update(from workout: Workout, in context: NSManagedObjectContext) {
        id = workout.id
        startDate = workout.startDate
        endDate = workout.endDate

        samples.forEach(context.delete)
        samples = Set(workout.samples.map { sample in
            let entity = HeartRateSampleEntity(context: context)
            entity.id = sample.id
            entity.bpm = Int64(sample.bpm)
            entity.date = sample.date
            return entity
        })
    }

    /// Builds the Domain value. Goes through Domain's validating initializers, so corrupt
    /// stored data (e.g. a BPM of 0) throws instead of reaching the UI.
    func toDomain() throws -> Workout {
        try Workout(
            id: id,
            startDate: startDate,
            endDate: endDate,
            samples: samples.map { sample in
                try HeartRateSample(id: sample.id, bpm: Int(sample.bpm), date: sample.date)
            }
        )
    }
}
