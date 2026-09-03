import Foundation

/// Everything the relay keeps from an Xcode Cloud webhook — and, by
/// construction, everything it does not: no commit, author, committer,
/// repository URL, pull request title or clone URL ever leaves the request
/// handler (D-0175 Q1). This struct is the privacy statement in code; the
/// site's policy lists these fields and no others.
///
/// Derived from the payloads captured in lot 0 (`andon-relay/Spike/fixtures`).
/// `BUILD_CREATED` is not an event here: the relay ignores it in v2.0.
public struct WebhookExtract: Hashable, Codable, Sendable {
    public enum Event: String, Hashable, Codable, Sendable {
        /// `BUILD_STARTED` — the actions are already listed (lot 0).
        case started
        /// `BUILD_COMPLETED` — with `completion`, and every action's outcome.
        case completed
    }

    /// One action of the run. `kind` is optional on purpose: the TestFlight
    /// distribution action carries no `actionType` in the webhook (lot 0).
    public struct Action: Hashable, Codable, Sendable, Identifiable {
        public enum Kind: String, Hashable, Codable, Sendable {
            case build
            case analyze
            case test
            case archive
        }

        public struct IssueCounts: Hashable, Codable, Sendable {
            public let analyzerWarnings: Int
            public let errors: Int
            public let testFailures: Int
            public let warnings: Int

            public init(analyzerWarnings: Int, errors: Int, testFailures: Int, warnings: Int) {
                self.analyzerWarnings = analyzerWarnings
                self.errors = errors
                self.testFailures = testFailures
                self.warnings = warnings
            }
        }

        public let id: String
        public let name: String
        public let kind: Kind?
        public let startedDate: Date?
        public let finishedDate: Date?
        public let progress: ExecutionProgress?
        public let completion: CompletionStatus?
        public let issueCounts: IssueCounts?

        public init(
            id: String,
            name: String,
            kind: Kind?,
            startedDate: Date? = nil,
            finishedDate: Date? = nil,
            progress: ExecutionProgress? = nil,
            completion: CompletionStatus? = nil,
            issueCounts: IssueCounts? = nil
        ) {
            self.id = id
            self.name = name
            self.kind = kind
            self.startedDate = startedDate
            self.finishedDate = finishedDate
            self.progress = progress
            self.completion = completion
            self.issueCounts = issueCounts
        }

        public var activityState: BuildActivityState.ActionState {
            BuildActivityState.ActionState(id: id, name: name, progress: progress, completion: completion)
        }
    }

    public let event: Event
    public let productID: String
    public let productName: String
    public let workflowID: String
    public let workflowName: String
    public let runID: String
    public let buildNumber: Int
    /// The branch or tag name — the only part of `scmGitReference` kept.
    public let referenceName: String?
    /// The pull request number when the build is a PR build — never its title.
    public let pullRequestNumber: Int?
    public let createdDate: Date?
    public let startedDate: Date?
    public let finishedDate: Date?
    public let progress: ExecutionProgress
    public let completion: CompletionStatus?
    public let actions: [Action]

    public init(
        event: Event,
        productID: String,
        productName: String,
        workflowID: String,
        workflowName: String,
        runID: String,
        buildNumber: Int,
        referenceName: String?,
        pullRequestNumber: Int?,
        createdDate: Date?,
        startedDate: Date?,
        finishedDate: Date?,
        progress: ExecutionProgress,
        completion: CompletionStatus?,
        actions: [Action]
    ) {
        self.event = event
        self.productID = productID
        self.productName = productName
        self.workflowID = workflowID
        self.workflowName = workflowName
        self.runID = runID
        self.buildNumber = buildNumber
        self.referenceName = referenceName
        self.pullRequestNumber = pullRequestNumber
        self.createdDate = createdDate
        self.startedDate = startedDate
        self.finishedDate = finishedDate
        self.progress = progress
        self.completion = completion
        self.actions = actions
    }

    public var isPullRequestBuild: Bool {
        pullRequestNumber != nil
    }

    /// The reference as the Live Activity shows it. The relay cannot localize,
    /// so a pull request reads "PR #n" in English on every device — the same
    /// wording Domain produces for the English locale (known limit, D-0175
    /// lot 1).
    public var displayReference: String? {
        if let pullRequestNumber {
            return "PR #\(pullRequestNumber)"
        }
        return referenceName
    }

    /// The frozen half of the Live Activity this webhook starts.
    public var activityIdentity: BuildActivityIdentity {
        BuildActivityIdentity(
            runID: runID,
            productID: productID,
            productName: productName,
            buildNumber: buildNumber,
            workflowName: workflowName,
            referenceName: displayReference
        )
    }

    /// The `content-state` this webhook pushes, actions included.
    public var activityState: BuildActivityState {
        BuildActivityState(
            progress: progress,
            completion: completion,
            startedDate: startedDate,
            finishedDate: finishedDate,
            actions: actions.map(\.activityState)
        )
    }
}
