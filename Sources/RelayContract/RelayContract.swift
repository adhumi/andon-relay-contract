import Foundation

/// The version of the wire contract between the Andon app and `andon-relay`.
/// Bumped only on an incompatible change; additive fields keep the version.
public enum RelayContractVersion {
    public static let current = 1
}

/// The relay's routes, shared so neither side spells them twice (D-0175 Q2).
///
/// Every `/v1/subscription` route authenticates with `Authorization: Bearer
/// <token>`, the token being the one `POST /v1/subscriptions` returned once.
/// The hook route authenticates by the token in its path alone: Xcode Cloud
/// webhooks carry no signature (lot 0), so the URL *is* the secret.
public enum RelayRoutes {
    /// `POST` a `DeviceRegistration`, receive a `SubscriptionCreated`. The only
    /// route without a bearer: it mints the token.
    public static let subscriptions = "/v1/subscriptions"
    /// `PUT` a `DeviceRegistration` to update tokens, toggles and preferences;
    /// `GET` a `SubscriptionStatus`; `DELETE` to opt out (immediate, total).
    public static let subscription = "/v1/subscription"
    /// `POST` to receive a test notification on the registered device.
    public static let subscriptionTest = "/v1/subscription/test"
    /// `GET /health` → `ok`.
    public static let health = "/health"

    /// The path Xcode Cloud posts to for one device.
    public static func hookPath(token: String) -> String {
        "/hooks/\(token)"
    }

    /// The URL the user pastes into App Store Connect, one per device, the
    /// same for every product they follow.
    public static func hookURL(relay base: URL, token: String) -> URL {
        base.appendingPathComponent("hooks").appendingPathComponent(token)
    }
}
