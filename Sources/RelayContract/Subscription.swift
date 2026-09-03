import Foundation

/// Which APNs gateway the device's tokens belong to. A debug build talks to
/// the sandbox; TestFlight and App Store builds to production. The device
/// knows, the relay does not — so the device says.
public enum APNSEnvironment: String, Hashable, Codable, Sendable {
    case sandbox
    case production
}

/// One device's registration with the relay — created once with
/// `POST /v1/subscriptions`, then replaced whole with `PUT /v1/subscription`
/// whenever a token rotates, a toggle flips or a preference changes.
///
/// One token = one device, bound at creation: there is no route to attach a
/// second device to an existing token (D-0175 Q2). Everything here is either
/// an APNs token, a boolean, an App Store Connect identifier or a version
/// string; nothing nominal, nothing from the ASC key.
public struct DeviceRegistration: Hashable, Codable, Sendable {
    public var contractVersion: Int
    /// The app's marketing version, so the relay can refuse a contract it no
    /// longer speaks and log which builds are in the field.
    public var appVersion: String
    public var apnsEnvironment: APNSEnvironment
    /// The APNs device token for alert and background pushes, hex-encoded.
    /// `nil` until the system hands it over (or when the user declined).
    public var notificationToken: String?
    /// The ActivityKit push-to-start token, hex-encoded. Rotates; the app
    /// re-registers on every update (lot 3).
    public var liveActivityStartToken: String?
    /// The two switches of the opt-in screen (Q4). Off means the relay sends
    /// nothing of that kind, whatever the tokens say.
    public var notificationsEnabled: Bool
    public var liveActivitiesEnabled: Bool
    public var preferences: NotificationPreferences

    public init(
        contractVersion: Int = RelayContractVersion.current,
        appVersion: String,
        apnsEnvironment: APNSEnvironment,
        notificationToken: String? = nil,
        liveActivityStartToken: String? = nil,
        notificationsEnabled: Bool = true,
        liveActivitiesEnabled: Bool = true,
        preferences: NotificationPreferences = .standard
    ) {
        self.contractVersion = contractVersion
        self.appVersion = appVersion
        self.apnsEnvironment = apnsEnvironment
        self.notificationToken = notificationToken
        self.liveActivityStartToken = liveActivityStartToken
        self.notificationsEnabled = notificationsEnabled
        self.liveActivitiesEnabled = liveActivitiesEnabled
        self.preferences = preferences
    }
}

/// The relay's answer to `POST /v1/subscriptions`: the bearer for every later
/// call, shown once and stored in the device Keychain, and the URL to paste
/// into App Store Connect. The relay keeps only a hash of the token.
public struct SubscriptionCreated: Hashable, Codable, Sendable {
    public let token: String
    public let hookURL: URL

    public init(token: String, hookURL: URL) {
        self.token = token
        self.hookURL = hookURL
    }
}

/// A product the relay has seen a webhook for under this token — by
/// identifier only; the app matches it against the products it knows.
public struct ProductConnection: Hashable, Codable, Sendable, Identifiable {
    public let productID: String
    /// When the last webhook for this product arrived. Drives the per-product
    /// status of the opt-in screen ("Connected · last build 2 min ago").
    public let lastEventDate: Date?

    public var id: String { productID }

    public init(productID: String, lastEventDate: Date?) {
        self.productID = productID
        self.lastEventDate = lastEventDate
    }
}

/// `GET /v1/subscription`: what the relay knows about this device.
public struct SubscriptionStatus: Hashable, Codable, Sendable {
    public let products: [ProductConnection]

    public init(products: [ProductConnection]) {
        self.products = products
    }
}
