import Foundation
import Testing
import Domain
@testable import Sensors

/// Specification for parsing the Bluetooth "Heart Rate Measurement" characteristic (0x2A37).
///
/// Layout, from the Bluetooth GATT specification:
/// - Byte 0 is a flags byte:
///   - bit 0: 0 = heart rate is 1 byte, 1 = heart rate is 2 bytes (little-endian)
///   - bit 1: sensor contact detected, bit 2: sensor contact feature supported
///   - bit 3: energy expended (2 bytes) follows, bit 4: RR-intervals follow
/// - Then the heart rate, then any optional fields (ignored here).
@Suite("Heart rate measurement parsing")
struct HeartRateMeasurementTests {

    // MARK: - Heart rate value

    @Test("Reads a 1-byte heart rate when bit 0 is clear")
    func eightBit() throws {
        let measurement = try HeartRateMeasurement(data: Data([0b0000_0000, 72]))

        #expect(measurement.bpm == 72)
    }

    @Test("Reads a 2-byte little-endian heart rate when bit 0 is set", arguments: [
        ([0x01, 0x2C, 0x01], 300),    // 0x012C
        ([0x01, 0x48, 0x00], 72),     // 0x0048: small value sent in the long format
        ([0x01, 0xFF, 0x00], 255)     // 0x00FF: low byte alone, high byte zero
    ] as [([UInt8], Int)])
    func sixteenBit(bytes: [UInt8], expected: Int) throws {
        let measurement = try HeartRateMeasurement(data: Data(bytes))

        #expect(measurement.bpm == expected)
    }

    // MARK: - Sensor contact

    @Test("Reports sensor contact from bits 1 and 2", arguments: [
        (UInt8(0b0000_0000), HeartRateMeasurement.Contact.notSupported),
        (UInt8(0b0000_0010), .notSupported),    // "detected" bit is meaningless without "supported"
        (UInt8(0b0000_0100), .lost),
        (UInt8(0b0000_0110), .detected)
    ])
    func contact(flags: UInt8, expected: HeartRateMeasurement.Contact) throws {
        let measurement = try HeartRateMeasurement(data: Data([flags, 80]))

        #expect(measurement.contact == expected)
    }

    // MARK: - Optional fields and reserved bits

    @Test("Ignores energy-expended and RR-interval fields after the heart rate")
    func ignoresOptionalFields() throws {
        // flags: energy (bit 3) + RR (bit 4); bpm 90; energy 0x0010; one RR interval 0x0400
        let data = Data([0b0001_1000, 90, 0x10, 0x00, 0x00, 0x04])

        #expect(try HeartRateMeasurement(data: data).bpm == 90)
    }

    @Test("Ignores reserved flag bits")
    func ignoresReservedBits() throws {
        #expect(try HeartRateMeasurement(data: Data([0b1110_0000, 65])).bpm == 65)
    }

    // MARK: - Malformed data

    @Test("Rejects empty data")
    func empty() {
        #expect(throws: HeartRateMeasurementError.empty) {
            try HeartRateMeasurement(data: Data())
        }
    }

    @Test("Rejects data too short for the format the flags announce", arguments: [
        [0x00],            // 1-byte format, value missing
        [0x01],            // 2-byte format, both bytes missing
        [0x01, 0x2C]       // 2-byte format, high byte missing
    ] as [[UInt8]])
    func truncated(bytes: [UInt8]) {
        #expect(throws: HeartRateMeasurementError.truncated) {
            try HeartRateMeasurement(data: Data(bytes))
        }
    }

    // MARK: - Converting to a sample

    let date = Date(timeIntervalSince1970: 1_000_000)

    @Test("Becomes a sample with the given date")
    func toSample() throws {
        let measurement = try HeartRateMeasurement(data: Data([0b0000_0110, 120]))

        let sample = try #require(try measurement.sample(at: date))

        #expect(sample.bpm == 120)
        #expect(sample.date == date)
    }

    @Test("Skips the reading when the sensor says it has lost skin contact")
    func lostContactIsSkipped() throws {
        // Monitors often send 0 or stale values when the strap is off; they aren't real readings.
        let measurement = try HeartRateMeasurement(data: Data([0b0000_0100, 0]))

        #expect(try measurement.sample(at: date) == nil)
    }

    @Test("A reading outside the valid BPM range is an error, not a sample")
    func invalidBPMThrows() throws {
        let measurement = try HeartRateMeasurement(data: Data([0b0000_0000, 0]))   // contact not reported

        #expect(throws: HeartRateSampleError.invalidBPM(0)) {
            try measurement.sample(at: date)
        }
    }
}
