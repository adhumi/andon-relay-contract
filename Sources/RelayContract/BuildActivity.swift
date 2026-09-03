import Foundation

/// The frozen identity of the build a Live Activity tracks (SPEC §3.6):
/// everything that cannot change while the run executes.
///
/// This is the `attributes` half of the ActivityKit payload. It lives here
/// so the relay's push-to-start encodes the very type the widget decodes
/// (D-0175 Q3 — no drift by construction). Domain adds the app-side
/// conveniences (`init(build:)`, the localized number label).
public struct BuildActivityIdentity: Hashable, Codable, Sendable {
    public let runID: String
    public let productID: String
    public let productName: String
    public let buildNumber: Int?
    public let workflowName: String?
    /// The reference being built, already worded for display ("PR #12", "main").
    public let referenceName: String?

    public init(
        runID: String,
        productID: String,
        productName: String,
        buildNumber: Int?,
        workflowName: String?,
        referenceName: String?
    ) {
        self.runID = runID
        self.productID = productID
        self.productName = productName
        self.buildNumber = buildNumber
        self.workflowName = workflowName
        self.referenceName = referenceName
    }
}

/// The changing half of a build's Live Activity: overall status, timing, and
/// the per-action progression of SPEC §3.6.
///
/// This is the `content-state` of every ActivityKit push. ActivityKit decodes
/// it with a default `JSONDecoder` — dates as seconds since 2001, optionals
/// absent when nil — so the relay must encode it with a default `JSONEncoder`
/// and never a custom strategy (`RelayContractTests` lock the shape).
public struct BuildActivityState: Hashable, Codable, Sendable {
    /// One action of the run, reduced to what the activity renders. Keyed by
    /// `id`: Xcode Cloud does not keep the order of actions stable between
    /// builds of the same workflow (lot 0).
    public struct ActionState: Hashable, Codable, Identifiable, Sendable {
        public let id: String
        public let name: String
        public let progress: ExecutionProgress?
        public let completion: CompletionStatus?

        public init(id: String, name: String, progress: ExecutionProgress?, completion: CompletionStatus?) {
            self.id = id
            self.name = name
            self.progress = progress
            self.completion = completion
        }

        public var isRunning: Bool {
            completion == nil && progress == .running
        }
    }

    public let progress: ExecutionProgress?
    public let completion: CompletionStatus?
    /// Anchor for the live elapsed timer; `nil` while the run is still queued.
    public let startedDate: Date?
    /// Freezes the timer on the final state left on screen after the run ends.
    public let finishedDate: Date?
    public let actions: [ActionState]

    public init(
        progress: ExecutionProgress?,
        completion: CompletionStatus?,
        startedDate: Date?,
        finishedDate: Date? = nil,
        actions: [ActionState] = []
    ) {
        self.progress = progress
        self.completion = completion
        self.startedDate = startedDate
        self.finishedDate = finishedDate
        self.actions = actions
    }

    public var isFinished: Bool {
        completion != nil
    }

    /// Total duration, once the run has both started and finished.
    public var duration: TimeInterval? {
        guard let startedDate, let finishedDate else { return nil }
        return finishedDate.timeIntervalSince(startedDate)
    }

    /// The action currently executing, for the headline ("Testing…").
    public var runningAction: ActionState? {
        actions.first(where: \.isRunning)
    }
}

/// The wire mirror of the app's `BuildActivityAttributes` (Domain, ActivityKit).
///
/// A push-to-start carries `"attributes-type": "BuildActivityAttributes"` and
/// `"attributes": { "identity": … }`; the relay encodes this struct to produce
/// the latter, and a Domain test asserts it encodes byte-for-byte like the
/// ActivityKit type it mirrors.
public struct LiveActivityAttributes: Hashable, Codable, Sendable {
    /// The value of `attributes-type` in the APNs payload: the Swift type name
    /// of the app's `ActivityAttributes` conformer.
    public static let typeName = "BuildActivityAttributes"

    public let identity: BuildActivityIdentity

    public init(identity: BuildActivityIdentity) {
        self.identity = identity
    }
}
