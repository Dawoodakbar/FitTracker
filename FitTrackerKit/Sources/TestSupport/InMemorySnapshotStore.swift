import Domain

/// A **fake** `SnapshotStore` that keeps the value in memory, for tests and previews.
public actor InMemorySnapshotStore<Value: Sendable>: SnapshotStore {
    private var value: Value?
    /// When set, every call throws it. Lets tests check how callers handle failures.
    private var failure: (any Error)?
    /// How many times `save` succeeded.
    public private(set) var saveCount = 0

    public init(_ value: Value? = nil) {
        self.value = value
    }

    /// Makes every following call throw `error`, until called again with `nil`.
    public func failNextCalls(with error: (any Error)?) {
        failure = error
    }

    public func load() throws -> Value? {
        if let failure { throw failure }
        return value
    }

    public func save(_ value: Value) throws {
        if let failure { throw failure }
        self.value = value
        saveCount += 1
    }
}
