/// The stats shown after a workout, computed once from a `Workout` and the user's zones.
public struct WorkoutSummary: Equatable, Sendable {
    public let duration: Duration
    /// Mean BPM across all samples, rounded. `nil` when the workout has no samples.
    public let averageBPM: Int?
    /// Highest BPM recorded. `nil` when the workout has no samples.
    public let maxBPM: Int?
    /// Time spent in each zone. Zones the user never reached have no entry.
    public let timeInZone: [HeartRateZone: Duration]

    /// The zone with the most time, or `nil` if no time was spent in any zone.
    /// On a tie the harder zone wins, since it says more about the workout's effort.
    public var mainZone: HeartRateZone? {
        // Tuples compare element by element: time first, then zone as the tie-break.
        timeInZone.max { ($0.value, $0.key) < ($1.value, $1.key) }?.key
    }

    public init(workout: Workout, calculator: HeartRateZoneCalculator) {
        let samples = workout.samples
        let bpms = samples.map(\.bpm)

        duration = workout.duration
        maxBPM = bpms.max()
        averageBPM = bpms.isEmpty
            ? nil
            : Int((Double(bpms.reduce(0, +)) / Double(bpms.count)).rounded())

        // Each sample's zone lasts until the next sample starts; the last one lasts until
        // the workout ends. Pairing every sample with its end date makes that one loop.
        let endDates = samples.dropFirst().map(\.date) + [workout.endDate]
        var timeInZone: [HeartRateZone: Duration] = [:]
        for (sample, endDate) in zip(samples, endDates) {
            guard let zone = sample.zone(using: calculator) else { continue }
            timeInZone[zone, default: .zero] += .seconds(endDate.timeIntervalSince(sample.date))
        }
        self.timeInZone = timeInZone
    }
}
