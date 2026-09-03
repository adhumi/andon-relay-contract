/// What a product or workflow notifies (SPEC §3.8, D-0175 Q4, #65).
public enum NotificationMode: String, Hashable, Codable, Sendable, CaseIterable {
    /// Succeeded and failed builds. Not canceled ones: Xcode Cloud emits no
    /// terminal webhook for a canceled build (lot 0, amendment a of D-0175).
    case all
    /// Failed builds only (`errored` counts as failed).
    case failuresOnly
    /// Nothing — and no Live Activity either.
    case none
}

/// The user's notification preferences, resolved workflow → product → default
/// (D-0175 Q4). Filtering happens on the relay: iOS displays every alert push
/// it receives, so the relay must not send what the user declined.
///
/// Keys are App Store Connect identifiers, never names — the relay stores
/// nothing nominal. The app sends the whole struct on every change and is
/// the source of truth.
public struct NotificationPreferences: Hashable, Codable, Sendable {
    public var defaultMode: NotificationMode
    /// Overrides by product identifier.
    public var products: [String: NotificationMode]
    /// Overrides by workflow identifier; wins over the product's.
    public var workflows: [String: NotificationMode]

    public init(
        defaultMode: NotificationMode = .all,
        products: [String: NotificationMode] = [:],
        workflows: [String: NotificationMode] = [:]
    ) {
        self.defaultMode = defaultMode
        self.products = products
        self.workflows = workflows
    }

    /// Everything on, no override — what an opt-in starts with (Q4: the user
    /// just asked to be told; the first success that bothers them is one tap
    /// away from a narrower setting).
    public static let standard = NotificationPreferences()

    private enum CodingKeys: String, CodingKey {
        case defaultMode, products, workflows
    }

    /// Tolerant on the wire: an absent map is an empty map, so a relay that
    /// knows nothing yet and an app that cleared everything encode the same.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultMode = try container.decodeIfPresent(NotificationMode.self, forKey: .defaultMode) ?? .all
        products = try container.decodeIfPresent([String: NotificationMode].self, forKey: .products) ?? [:]
        workflows = try container.decodeIfPresent([String: NotificationMode].self, forKey: .workflows) ?? [:]
    }

    /// The effective mode for a run: its workflow's override, else its
    /// product's, else the default.
    public func mode(productID: String, workflowID: String?) -> NotificationMode {
        if let workflowID, let mode = workflows[workflowID] {
            return mode
        }
        if let mode = products[productID] {
            return mode
        }
        return defaultMode
    }

    /// Whether a finished run deserves an alert. Canceled and skipped runs
    /// never do — nor could they, having no webhook (lot 0).
    public func notifies(_ completion: CompletionStatus, productID: String, workflowID: String?) -> Bool {
        switch mode(productID: productID, workflowID: workflowID) {
        case .none:
            return false
        case .failuresOnly:
            return completion.isFailure
        case .all:
            return completion == .succeeded || completion.isFailure
        }
    }

    /// A Live Activity is not a notification: `failuresOnly` keeps it (the
    /// start push cannot know the outcome; the end push carries no alert).
    /// Only `none` — at any level of the chain — turns it off (D-0175 Q4).
    public func allowsLiveActivities(productID: String, workflowID: String?) -> Bool {
        mode(productID: productID, workflowID: workflowID) != .none
    }
}
