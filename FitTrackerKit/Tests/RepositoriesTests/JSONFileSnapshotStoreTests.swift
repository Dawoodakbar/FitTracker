import Foundation
import Testing
import Domain
import Repositories

@Suite("JSON file snapshot store")
struct JSONFileSnapshotStoreTests {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "FitTrackerTests-\(UUID().uuidString)/journal.json")

    @Test("Loads nil before anything is saved")
    func emptyLoad() async throws {
        #expect(try await JSONFileSnapshotStore<PrayerJournal>(fileURL: url).load() == nil)
    }

    @Test("Saves and loads the same value, creating the folder")
    func roundTrip() async throws {
        var journal = PrayerJournal()
        journal.set(.onTime, for: .fajr, on: Day(year: 2027, month: 3, day: 3))
        let store = JSONFileSnapshotStore<PrayerJournal>(fileURL: url)

        try await store.save(journal)

        #expect(try await JSONFileSnapshotStore<PrayerJournal>(fileURL: url).load() == journal)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}
