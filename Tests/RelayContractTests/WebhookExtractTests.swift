import Foundation
import Testing
import RelayContract

@Suite("WebhookExtract")
struct WebhookExtractTests {
    private let referenceDate = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func started() -> WebhookExtract {
        WebhookExtract(
            event: .started,
            productID: "prod-1",
            productName: "Lantern",
            workflowID: "wf-1",
            workflowName: "Main",
            runID: "run-838",
            buildNumber: 838,
            referenceName: "main",
            pullRequestNumber: nil,
            createdDate: referenceDate.addingTimeInterval(-11),
            startedDate: referenceDate,
            finishedDate: nil,
            progress: .running,
            completion: nil,
            actions: [
                WebhookExtract.Action(id: "a-1", name: "Archive - iOS", kind: .archive, startedDate: referenceDate, progress: .running),
                // The TestFlight distribution action has no `actionType` (lot 0).
                WebhookExtract.Action(id: "a-2", name: "Tests TestFlight internes - iOS", kind: nil, progress: .pending),
            ]
        )
    }

    @Test("A started webhook yields the Live Activity identity and state with its actions")
    func liveActivityProjection() {
        let extract = started()
        let identity = extract.activityIdentity
        #expect(identity.runID == "run-838")
        #expect(identity.buildNumber == 838)
        #expect(identity.workflowName == "Main")
        #expect(identity.referenceName == "main")

        let state = extract.activityState
        #expect(state.progress == .running)
        #expect(state.startedDate == referenceDate)
        #expect(state.actions.map(\.id) == ["a-1", "a-2"])
        #expect(state.runningAction?.name == "Archive - iOS")
        #expect(extract.isPullRequestBuild == false)
    }

    @Test("A pull request build is referenced by its number, never its title")
    func pullRequestReference() {
        let extract = WebhookExtract(
            event: .completed,
            productID: "prod-1",
            productName: "Lantern",
            workflowID: "wf-2",
            workflowName: "Pull Request",
            runID: "run-837",
            buildNumber: 837,
            referenceName: "feature/example",
            pullRequestNumber: 367,
            createdDate: nil,
            startedDate: referenceDate,
            finishedDate: referenceDate.addingTimeInterval(168),
            progress: .complete,
            completion: .failed,
            actions: []
        )
        #expect(extract.isPullRequestBuild)
        #expect(extract.displayReference == "PR #367")
        #expect(extract.activityIdentity.referenceName == "PR #367")
        #expect(extract.activityState.isFinished)
        #expect(extract.activityState.duration == 168)
    }

    @Test("Round-trips through JSON, optional kind included")
    func codable() throws {
        let extract = started()
        let data = try JSONEncoder().encode(extract)
        let decoded = try JSONDecoder().decode(WebhookExtract.self, from: data)
        #expect(decoded == extract)
        #expect(decoded.actions[1].kind == nil)
    }
}
