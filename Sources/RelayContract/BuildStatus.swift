/// Where a build run or action currently stands in its lifecycle.
///
/// Lives in the contract because it crosses the network inside
/// `BuildActivityState`; Domain re-exports it under the same name.
public enum ExecutionProgress: String, Hashable, Codable, Sendable {
    case pending
    case running
    case complete
}

/// How a completed build run or action ended.
public enum CompletionStatus: String, Hashable, Codable, Sendable {
    case succeeded
    case failed
    case errored
    case canceled
    case skipped

    /// `failed` and `errored` both read as a failure to the user (SPEC §6.4,
    /// D-0175 Q4): the second is Xcode Cloud's own fault, the outcome is the
    /// same red build.
    public var isFailure: Bool {
        switch self {
        case .failed, .errored: true
        case .succeeded, .canceled, .skipped: false
        }
    }
}
