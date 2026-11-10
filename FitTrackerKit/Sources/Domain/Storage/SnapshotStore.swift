/// Saves and loads one whole value (a journal, a medication list), hiding where it lives.
///
/// The wellness features each keep a small value type as their single source of truth and
/// save all of it after every change. Features depend on this protocol; the app injects a
/// file-backed store and tests inject an in-memory fake.
public protocol SnapshotStore<Value>: Sendable {
    associatedtype Value: Sendable

    /// The saved value, or `nil` if nothing has been saved yet.
    func load() async throws -> Value?

    /// Replaces the saved value.
    func save(_ value: Value) async throws
}
