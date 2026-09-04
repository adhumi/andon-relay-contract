import Foundation
import Testing
import RelayContract

@Suite("Subscription wire types")
struct SubscriptionTests {
    @Test("A registration round-trips with its preferences and toggles")
    func registrationCodable() throws {
        let registration = DeviceRegistration(
            appVersion: "2.0",
            apnsEnvironment: .production,
            notificationToken: "abcd",
            liveActivityStartToken: nil,
            notificationsEnabled: true,
            liveActivitiesEnabled: false,
            preferences: NotificationPreferences(defaultMode: .failuresOnly)
        )
        let data = try JSONEncoder().encode(registration)
        let decoded = try JSONDecoder().decode(DeviceRegistration.self, from: data)
        #expect(decoded == registration)
        #expect(decoded.contractVersion == RelayContractVersion.current)
    }

    @Test("A registration decodes from the JSON an app would send")
    func registrationFromJSON() throws {
        let json = """
        {"contractVersion":1,"appVersion":"2.0","apnsEnvironment":"sandbox",
         "notificationToken":"00ff","notificationsEnabled":true,"liveActivitiesEnabled":true,
         "preferences":{"defaultMode":"all"}}
        """
        let decoded = try JSONDecoder().decode(DeviceRegistration.self, from: try #require(json.data(using: .utf8)))
        #expect(decoded.apnsEnvironment == .sandbox)
        #expect(decoded.notificationToken == "00ff")
        #expect(decoded.liveActivityStartToken == nil)
        #expect(decoded.preferences == .standard)
    }

    @Test("The created subscription carries the token and the hook URL")
    func createdCodable() throws {
        let created = SubscriptionCreated(
            token: "t0k3n",
            hookURL: try #require(URL(string: "https://relay.andon-ci.app/hooks/t0k3n"))
        )
        let decoded = try JSONDecoder().decode(SubscriptionCreated.self, from: JSONEncoder().encode(created))
        #expect(decoded == created)
    }

    @Test("The status lists products by identifier with their last event")
    func statusCodable() throws {
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let status = SubscriptionStatus(products: [
            ProductConnection(productID: "prod-1", lastEventDate: date),
            ProductConnection(productID: "prod-2", lastEventDate: nil),
        ])
        let decoded = try JSONDecoder().decode(SubscriptionStatus.self, from: JSONEncoder().encode(status))
        #expect(decoded == status)
        #expect(decoded.products.map(\.id) == ["prod-1", "prod-2"])
    }

    @Test("The hook URL is the relay base plus the token")
    func hookURL() throws {
        let base = try #require(URL(string: "https://relay.andon-ci.app"))
        #expect(RelayRoutes.hookURL(relay: base, token: "abc").absoluteString == "https://relay.andon-ci.app/hooks/abc")
        #expect(RelayRoutes.hookPath(token: "abc") == "/hooks/abc")
    }
}

@Suite("RelayRoutes — Live Activity (lot 3)")
struct LiveActivityRoutesTests {
    @Test("Per-run paths match the server's patterns")
    func paths() {
        #expect(RelayRoutes.activityTokenPath(runID: "run-1") == "/v1/subscription/runs/run-1/activity-token")
        #expect(RelayRoutes.runTerminatedPath(runID: "run-1") == "/v1/subscription/runs/run-1/terminated")
        #expect(RelayRoutes.activityTokenPattern.replacingOccurrences(of: "{runID}", with: "run-1") == RelayRoutes.activityTokenPath(runID: "run-1"))
        #expect(RelayRoutes.runTerminatedPattern.replacingOccurrences(of: "{runID}", with: "run-1") == RelayRoutes.runTerminatedPath(runID: "run-1"))
    }

    @Test("The activity token registration is one hex string on the wire")
    func tokenRegistration() throws {
        let data = try JSONEncoder().encode(LiveActivityTokenRegistration(token: "c0ffee"))
        #expect(String(decoding: data, as: UTF8.self) == #"{"token":"c0ffee"}"#)
    }
}
