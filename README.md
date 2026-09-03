# RelayContract

The wire contract between the [Andon](https://github.com/adhumi/andon) iOS
app and its notification relay, `andon-relay`: the only types that cross the
network between the two, and nothing else. Foundation only, no dependency,
builds on Linux.

- **Source of truth**: `Packages/RelayContract` in the `andon` repository.
- **Mirror**: `adhumi/andon-relay-contract` is generated from it by a GitHub
  Actions workflow on every change to `main` (`git subtree split`), so that
  SwiftPM can consume it by URL. **Do not edit the mirror** — changes are
  overwritten on the next push. Releases are tags on the mirror.

## What is in it

| Type | Role |
|---|---|
| `ExecutionProgress`, `CompletionStatus` | build and action lifecycle, shared with the Live Activity |
| `BuildActivityIdentity`, `BuildActivityState`, `LiveActivityAttributes` | the ActivityKit `attributes` and `content-state` the relay pushes |
| `WebhookExtract` | everything the relay keeps from an Xcode Cloud webhook — the privacy statement in code |
| `NotificationPreferences`, `NotificationMode` | per-product / per-workflow notification settings, resolved workflow → product → default |
| `DeviceRegistration`, `SubscriptionCreated`, `SubscriptionStatus`, `ProductConnection`, `APNSEnvironment` | the subscription API bodies |
| `RelayPushInfo` | the `userInfo["andon"]` of every push |
| `RelayNotificationText` | the `loc-key`s of the relay's alerts, rendered by the device |
| `RelayRoutes`, `RelayContractVersion` | routes and contract version |

Product decisions live in `DECISIONS.md` of the `andon` repository (D-0175).
