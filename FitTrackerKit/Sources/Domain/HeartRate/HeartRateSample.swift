import Foundation

/// A single heart-rate reading taken at a point in time.
///
/// Samples are immutable values: once created, a reading never changes.
public struct HeartRateSample: Identifiable, Hashable, Sendable {
    /// BPM values a sample can hold. `0` is excluded because sensors report it when they
    /// lose skin contact, and that should never be saved as a real reading.
    public static let validBPM = 1...300

    /// Stable identity, also used as the idempotency key when the sample syncs to the server.
    public let id: UUID
    /// Beats per minute, always within `validBPM`.
    public let bpm: Int
    /// When the reading was taken.
    public let date: Date

    /// Creates a validated sample.
    /// - Parameter id: Defaults to a new `UUID`. Pass one explicitly when loading saved data.
    /// - Throws: `HeartRateSampleError.invalidBPM` if `bpm` is outside `validBPM`.
    public init(id: UUID = UUID(), bpm: Int, date: Date) throws(HeartRateSampleError) {
        guard Self.validBPM.contains(bpm) else { throw .invalidBPM(bpm) }
        self.id = id
        self.bpm = bpm
        self.date = date
    }

    /// The zone this sample falls into, or `nil` if the user is resting.
    ///
    /// The calculator is passed in because a sample doesn't know the user's max heart rate.
    public func zone(using calculator: HeartRateZoneCalculator) -> HeartRateZone? {
        calculator.zone(for: bpm)
    }
}
