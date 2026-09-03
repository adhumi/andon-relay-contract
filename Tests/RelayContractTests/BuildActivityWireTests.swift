import Foundation
import Testing
import RelayContract

/// Locks the JSON ActivityKit will decode: default encoder, dates as seconds
/// since 2001, optionals absent when nil. The relay reuses these exact
/// encoders; if this suite breaks, so does every Live Activity push.
@Suite("BuildActivityState on the wire")
struct BuildActivityWireTests {
    private let referenceDate = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    @Test("A running state encodes with the keys and date format ActivityKit expects")
    func runningStateShape() throws {
        let state = BuildActivityState(
            progress: .running,
            completion: nil,
            startedDate: referenceDate,
            actions: [
                BuildActivityState.ActionState(id: "a-1", name: "Build", progress: .complete, completion: .succeeded),
                BuildActivityState.ActionState(id: "a-2", name: "Test", progress: .running, completion: nil),
            ]
        )
        let json = try #require(String(data: encoder.encode(state), encoding: .utf8))
        #expect(json == #"{"actions":[{"completion":"succeeded","id":"a-1","name":"Build","progress":"complete"},{"id":"a-2","name":"Test","progress":"running"}],"progress":"running","startedDate":800000000}"#)
    }

    @Test("A finished state carries completion and the frozen finished date")
    func finishedStateShape() throws {
        let state = BuildActivityState(
            progress: .complete,
            completion: .failed,
            startedDate: referenceDate,
            finishedDate: referenceDate.addingTimeInterval(168)
        )
        let json = try #require(String(data: encoder.encode(state), encoding: .utf8))
        #expect(json == #"{"actions":[],"completion":"failed","finishedDate":800000168,"progress":"complete","startedDate":800000000}"#)
        #expect(state.duration == 168)
        #expect(state.isFinished)
    }

    @Test("The JSON a relay would send decodes back to the same state")
    func decodesRelayJSON() throws {
        let json = #"{"progress":"running","startedDate":800000000,"actions":[{"id":"a-2","name":"Test","progress":"running"}]}"#
        let state = try JSONDecoder().decode(BuildActivityState.self, from: try #require(json.data(using: .utf8)))
        #expect(state.progress == .running)
        #expect(state.completion == nil)
        #expect(state.startedDate == referenceDate)
        #expect(state.finishedDate == nil)
        #expect(state.runningAction?.id == "a-2")
    }

    @Test("The identity encodes as the `attributes` of a push-to-start")
    func attributesShape() throws {
        let identity = BuildActivityIdentity(
            runID: "run-1",
            productID: "prod-1",
            productName: "Lantern",
            buildNumber: 42,
            workflowName: "CI",
            referenceName: "main"
        )
        let json = try #require(String(data: encoder.encode(LiveActivityAttributes(identity: identity)), encoding: .utf8))
        #expect(json == #"{"identity":{"buildNumber":42,"productID":"prod-1","productName":"Lantern","referenceName":"main","runID":"run-1","workflowName":"CI"}}"#)
        #expect(LiveActivityAttributes.typeName == "BuildActivityAttributes")
    }

    @Test("Optional identity fields are absent, not null")
    func sparseIdentity() throws {
        let identity = BuildActivityIdentity(
            runID: "run-1",
            productID: "prod-1",
            productName: "Lantern",
            buildNumber: nil,
            workflowName: nil,
            referenceName: nil
        )
        let json = try #require(String(data: encoder.encode(identity), encoding: .utf8))
        #expect(json == #"{"productID":"prod-1","productName":"Lantern","runID":"run-1"}"#)
    }
}
