import Foundation
import Testing
import RelayContract

@Suite("NotificationPreferences")
struct NotificationPreferencesTests {
    @Test("A workflow override wins over its product's, which wins over the default")
    func inheritance() {
        let preferences = NotificationPreferences(
            defaultMode: .all,
            products: ["prod-1": .failuresOnly],
            workflows: ["wf-nightly": .all]
        )
        #expect(preferences.mode(productID: "prod-1", workflowID: "wf-nightly") == .all)
        #expect(preferences.mode(productID: "prod-1", workflowID: "wf-pr") == .failuresOnly)
        #expect(preferences.mode(productID: "prod-1", workflowID: nil) == .failuresOnly)
        #expect(preferences.mode(productID: "prod-2", workflowID: nil) == .all)
    }

    @Test("The standard preferences notify everything, override nothing")
    func standard() {
        #expect(NotificationPreferences.standard.defaultMode == .all)
        #expect(NotificationPreferences.standard.products.isEmpty)
        #expect(NotificationPreferences.standard.workflows.isEmpty)
    }

    @Test(
        "`all` notifies successes and failures, never a canceled or skipped run",
        arguments: [
            (CompletionStatus.succeeded, true),
            (.failed, true),
            (.errored, true),
            (.canceled, false),
            (.skipped, false),
        ]
    )
    func allMode(completion: CompletionStatus, expected: Bool) {
        let preferences = NotificationPreferences(defaultMode: .all)
        #expect(preferences.notifies(completion, productID: "p", workflowID: nil) == expected)
    }

    @Test(
        "`failuresOnly` notifies failed and errored runs only",
        arguments: [
            (CompletionStatus.succeeded, false),
            (.failed, true),
            (.errored, true),
            (.canceled, false),
        ]
    )
    func failuresOnlyMode(completion: CompletionStatus, expected: Bool) {
        let preferences = NotificationPreferences(defaultMode: .failuresOnly)
        #expect(preferences.notifies(completion, productID: "p", workflowID: nil) == expected)
    }

    @Test("`none` notifies nothing and turns Live Activities off; `failuresOnly` keeps them")
    func liveActivities() {
        let preferences = NotificationPreferences(
            defaultMode: .all,
            products: ["silent": .none, "quiet": .failuresOnly]
        )
        #expect(preferences.notifies(.failed, productID: "silent", workflowID: nil) == false)
        #expect(preferences.allowsLiveActivities(productID: "silent", workflowID: nil) == false)
        #expect(preferences.allowsLiveActivities(productID: "quiet", workflowID: nil))
        #expect(preferences.allowsLiveActivities(productID: "other", workflowID: nil))
    }

    @Test("A `none` workflow inside a product that notifies also silences its Live Activity")
    func noneWorkflowCutsLiveActivity() {
        let preferences = NotificationPreferences(workflows: ["wf-docs": .none])
        #expect(preferences.allowsLiveActivities(productID: "p", workflowID: "wf-docs") == false)
        #expect(preferences.allowsLiveActivities(productID: "p", workflowID: "wf-app"))
    }

    @Test("Round-trips through JSON with the wire keys")
    func codable() throws {
        let preferences = NotificationPreferences(
            defaultMode: .failuresOnly,
            products: ["prod-1": .all],
            workflows: ["wf-1": .none]
        )
        let data = try JSONEncoder().encode(preferences)
        let decoded = try JSONDecoder().decode(NotificationPreferences.self, from: data)
        #expect(decoded == preferences)

        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"failuresOnly\""))
        #expect(json.contains("\"wf-1\":\"none\""))
    }

    @Test("A payload with only the default decodes with empty overrides")
    func tolerantDecoding() throws {
        let data = try #require(#"{"defaultMode":"none"}"#.data(using: .utf8))
        let decoded = try JSONDecoder().decode(NotificationPreferences.self, from: data)
        #expect(decoded.defaultMode == .none)
        #expect(decoded.products.isEmpty)
        #expect(decoded.workflows.isEmpty)

        let empty = try JSONDecoder().decode(NotificationPreferences.self, from: try #require("{}".data(using: .utf8)))
        #expect(empty == .standard)
    }
}
