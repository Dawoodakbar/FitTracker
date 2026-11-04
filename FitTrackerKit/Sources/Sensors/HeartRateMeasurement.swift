import Foundation
import Domain

/// Why a Heart Rate Measurement packet couldn't be read.
public enum HeartRateMeasurementError: Error, Equatable, Sendable {
    /// The packet had no bytes at all.
    case empty
    /// The packet ended before the heart-rate value announced by its flags.
    case truncated
}

/// One packet from the standard Bluetooth "Heart Rate Measurement" characteristic (0x2A37).
///
/// Only the fields FitTracker uses are read: the heart rate and the sensor-contact status.
/// Energy-expended and RR-interval fields are skipped.
public struct HeartRateMeasurement: Equatable, Sendable {
    /// Whether the monitor can tell if it's touching skin, and if so whether it is.
    public enum Contact: Equatable, Sendable {
        /// The monitor doesn't report contact, so readings are taken as valid.
        case notSupported
        /// The monitor reports it has lost skin contact; its value isn't reliable.
        case lost
        /// The monitor reports good skin contact.
        case detected
    }

    public let bpm: Int
    public let contact: Contact

    /// Parses a packet.
    /// - Throws: `HeartRateMeasurementError.empty` or `.truncated` for malformed data.
    public init(data: Data) throws(HeartRateMeasurementError) {
        // `Data` can be a slice whose indices don't start at 0, so copy to an array first.
        let bytes = [UInt8](data)
        guard let flags = bytes.first else { throw .empty }

        // Bit 0 picks the heart-rate width. Bit 2 says contact is supported, bit 1 says detected.
        let isSixteenBit = flags & 0b0000_0001 != 0
        let contactSupported = flags & 0b0000_0100 != 0
        let contactDetected = flags & 0b0000_0010 != 0

        if isSixteenBit {
            guard bytes.count >= 3 else { throw .truncated }
            // Little-endian: the low byte comes first.
            bpm = Int(bytes[1]) | Int(bytes[2]) << 8
        } else {
            guard bytes.count >= 2 else { throw .truncated }
            bpm = Int(bytes[1])
        }

        contact = switch (contactSupported, contactDetected) {
        case (false, _): .notSupported
        case (true, false): .lost
        case (true, true): .detected
        }
    }

    /// Converts to a Domain reading taken at `date`.
    ///
    /// - Returns: `nil` when the monitor reports lost contact, since that value isn't a real
    ///   reading and shouldn't be recorded.
    /// - Throws: `HeartRateSampleError.invalidBPM` if the value is outside the valid range.
    public func sample(at date: Date) throws(HeartRateSampleError) -> HeartRateSample? {
        guard contact != .lost else { return nil }
        return try HeartRateSample(bpm: bpm, date: date)
    }
}
