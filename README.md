# otpless-event-io-ios

The iOS telemetry / event pipeline used by the OTPLESS iOS auth SDK.

**Pod:** `OtplessEventIO` · **SPM:** `Package.swift` (product `OtplessEventIO`)

## Who depends on this

`otpless-headless-iOS-sdk` (the `OtplessBM` SDK), through both distribution channels:

| Channel | Declaration |
|---|---|
| Swift Package Manager | `.product(name: "OtplessEventIO", package: "otpless-event-io-ios")` |
| CocoaPods | `core.dependency 'OtplessEventIO', '~> 1.0'` |

That SDK is merchant-facing, so this library ships inside merchant applications.

**Note the CocoaPods declaration is a range (`~> 1.0`), not an exact pin.** Every other native dependency in this workspace is pinned exactly, precisely so a dependency release cannot change SDK behavior without a reviewed PR. Here, publishing `1.1.0` would be picked up by merchant builds automatically. Consider that when releasing: a minor version bump is effectively an unreviewed change to the shipped iOS SDK.

## Layout

| Path | What it is |
|---|---|
| `Sources/` | the library |
| `Tests/` | unit tests |
| `OtplessEventIO.podspec` | CocoaPods spec — also where the version is set |
| `Package.swift` | SPM manifest |

## Build and test

```bash
swift build
swift test

pod lib lint OtplessEventIO.podspec     # validate before publishing
```

## Releasing

The version lives in `OtplessEventIO.podspec`. Because the consuming SDK depends on `~> 1.0`:

- a **patch or minor** release reaches merchant builds without any change in the iOS SDK;
- a **major** release does not, and requires a coordinated bump in `otpless-headless-iOS-sdk`.

Tag the repo at the released version so the workspace's release-train tooling can identify what shipped. (The Android side has a standing counter-example: `otpless-headless-sdk` published `0.9.0` to Maven Central with no git tag, leaving no way to tell from the repo what was released.)

## Before you change the public API

This repo has **no verification gate and no committed API baseline**, while the consuming iOS SDK is adopting `swift-api-digester` against one. Nothing here catches a breaking change; it surfaces in the consumer, or after release.

Until that is closed (tracked in the workspace hub's `docs/ARCHITECTURE.md` readiness section), treat any change to a `public` symbol as breaking until proven otherwise, and check the consumer directly:

```bash
# from a hub checkout
grep -rn "SymbolName" ../../sdks/otpless-headless-iOS-sdk/Sources --include='*.swift'
```

## Workspace context

Registered as a submodule of the `native-sdks` workspace hub, which owns the cross-repo protocols: dependency-bump flow, the response-contract spine, and parity rules. In a hub checkout, the hub's `CLAUDE.md` loads automatically and applies.
