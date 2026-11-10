import Foundation
import Domain

/// Saves one `Codable` value as a JSON file. Used for the wellness journals, which are small
/// and always read and written whole.
///
/// An `actor`, so two saves can never interleave and corrupt the file.
public actor JSONFileSnapshotStore<Value: Codable & Sendable>: SnapshotStore {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// A store for `<Application Support>/FitTracker/<name>.json`.
    public init(name: String) {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "FitTracker", directoryHint: .isDirectory)
        self.init(fileURL: folder.appending(path: "\(name).json"))
    }

    public func load() throws -> Value? {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return nil }
        return try JSONDecoder().decode(Value.self, from: Data(contentsOf: fileURL))
    }

    public func save(_ value: Value) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        // Atomic: a crash mid-write leaves the old file intact. Protected: health details
        // are encrypted on disk while the phone is locked.
        try JSONEncoder().encode(value).write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
