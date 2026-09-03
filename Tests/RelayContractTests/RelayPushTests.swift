import Foundation
import Testing
import RelayContract

@Suite("RelayPushInfo")
struct RelayPushTests {
    @Test("Travels through a push's userInfo and back")
    func userInfoRoundTrip() throws {
        let info = RelayPushInfo(kind: .buildFinished, runID: "run-1", productID: "prod-1")
        let userInfo: [AnyHashable: Any] = [
            "aps": ["alert": ["loc-key": RelayNotificationText.titleKeySucceeded]],
            RelayPushInfo.userInfoKey: try info.userInfoValue(),
        ]
        let decoded = try #require(RelayPushInfo(userInfo: userInfo))
        #expect(decoded == info)
        #expect(decoded.version == RelayContractVersion.current)
    }

    @Test("A push without the relay's key is not the relay's")
    func foreignPush() {
        #expect(RelayPushInfo(userInfo: ["aps": ["content-available": 1]]) == nil)
        #expect(RelayPushInfo(userInfo: [RelayPushInfo.userInfoKey: "not an object"]) == nil)
    }

    @Test("A tick names its run, a connection its product")
    func kinds() throws {
        let tick = RelayPushInfo(kind: .tick, runID: "run-1")
        let connected = RelayPushInfo(kind: .connected, productID: "prod-1")
        #expect(try tick.userInfoValue()["kind"] as? String == "tick")
        #expect(try connected.userInfoValue()["productID"] as? String == "prod-1")
        #expect(try connected.userInfoValue()["runID"] == nil)
    }

    @Test("Failed and errored share the failure title; the catalog list covers every key")
    func notificationKeys() {
        #expect(RelayNotificationText.titleKey(for: .failed) == RelayNotificationText.titleKeyFailed)
        #expect(RelayNotificationText.titleKey(for: .errored) == RelayNotificationText.titleKeyFailed)
        #expect(RelayNotificationText.titleKey(for: .succeeded) == RelayNotificationText.titleKeySucceeded)
        #expect(Set(RelayNotificationText.allKeys).count == RelayNotificationText.allKeys.count)
        #expect(RelayNotificationText.allKeys.allSatisfy { $0.hasPrefix("relay.notification.") })
    }
}
