import Foundation

/// What the relay puts in every push's `userInfo`, under the `andon` key —
/// alert, silent tick or test alike. The app reads it to route: open the
/// build's detail from a tapped alert (the deep link of D-0030), poll the
/// run on a tick, refresh the opt-in screen when a product connects.
///
/// Live Activity pushes do not carry it: their content is the `content-state`
/// (`BuildActivityState`) and ActivityKit never hands `userInfo` to the app.
public struct RelayPushInfo: Hashable, Codable, Sendable {
    public enum Kind: String, Hashable, Codable, Sendable {
        /// An alert for a finished build; `runID` and `productID` set.
        case buildFinished
        /// A silent `content-available` push while a build runs (D-0175 Q1):
        /// poll the run, refresh the Live Activity locally; `runID` set.
        case tick
        /// The alert `POST /v1/subscription/test` sends.
        case test
        /// Silent: the relay saw the first webhook for `productID` — the
        /// opt-in screen can move that product to "connected".
        case connected
    }

    /// The top-level `userInfo` key. Every other key in the payload is Apple's.
    public static let userInfoKey = "andon"

    public let version: Int
    public let kind: Kind
    public let runID: String?
    public let productID: String?

    public init(kind: Kind, runID: String? = nil, productID: String? = nil, version: Int = RelayContractVersion.current) {
        self.version = version
        self.kind = kind
        self.runID = runID
        self.productID = productID
    }

    /// Reads the info back from a delivered notification's `userInfo`;
    /// `nil` when the push is not the relay's or predates this contract.
    public init?(userInfo: [AnyHashable: Any]) {
        guard let raw = userInfo[Self.userInfoKey],
              JSONSerialization.isValidJSONObject(raw),
              let data = try? JSONSerialization.data(withJSONObject: raw),
              let decoded = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = decoded
    }

    /// The JSON object to place under `userInfoKey` in the APNs payload.
    public func userInfoValue() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        // Encodable structs always serialize to a JSON object; the cast can
        // only fail if the encoder is changed to something exotic.
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

/// The localization keys of the relay's alerts. The relay sends `loc-key`
/// and `loc-args`; the device renders them from the **app target's** string
/// catalog (`Bundle.main`, which is where APNs looks — not a package's).
/// Lot 2 adds every key listed in `allKeys` to that catalog, and a test
/// there asserts none is missing.
public enum RelayNotificationText {
    /// Title of a finished build. Arguments: `%1$@` product name, `%2$@`
    /// build number (digits only — the relay cannot localize "#").
    public static func titleKey(for completion: CompletionStatus) -> String {
        completion.isFailure ? titleKeyFailed : titleKeySucceeded
    }

    public static let titleKeySucceeded = "relay.notification.title.succeeded"
    public static let titleKeyFailed = "relay.notification.title.failed"

    /// Body: `%1$@` workflow name, `%2$@` reference ("main", "PR #12").
    public static let bodyKeyWorkflowAndReference = "relay.notification.body.workflowAndReference"
    /// Body when the run has no reference: `%1$@` workflow name.
    public static let bodyKeyWorkflowOnly = "relay.notification.body.workflowOnly"

    /// The test alert of `POST /v1/subscription/test`, no arguments.
    public static let testTitleKey = "relay.notification.test.title"
    public static let testBodyKey = "relay.notification.test.body"

    /// Every key the app's catalog must carry.
    public static let allKeys: [String] = [
        titleKeySucceeded,
        titleKeyFailed,
        bodyKeyWorkflowAndReference,
        bodyKeyWorkflowOnly,
        testTitleKey,
        testBodyKey,
    ]
}
