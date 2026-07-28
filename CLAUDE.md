# CLAUDE.md — otpless-event-io-ios

**This repo is a shared library, not an SDK.** No merchant ever installs it, reads its
docs, or calls its API directly. It has no SDK-GUIDE, no artifact-size budget, and no
merchant-facing response contract of its own. What it has is a **public surface that
other people's release artifacts carry into production**, and that is the thing this
repo has to protect.

## What it publishes

| | |
|---|---|
| CocoaPod | `OtplessEventIO` (`OtplessEventIO.podspec`, currently `1.0.0`) |
| SPM product | `OtplessEventIO` (`Package.swift`) |
| Platforms | iOS 13+, macOS 10.15+ |
| Entry point | `OtplessEventIO` (an `enum` namespace of static members) over the `OtplessEventIOContract` protocol |
| What it does | Captures device and tracking events, persists them locally in SQLite, and forwards them to the OTPLESS events backend with retry for failed sends |

## Who consumes it, at which version

| Consumer | Constraint | Where |
|---|---|---|
| `otpless-headless-iOS-sdk` (`OtplessBM`) | CocoaPods `'OtplessEventIO', '~> 1.0'` | `OtplessBM.podspec` |
| `otpless-headless-iOS-sdk` (`OtplessBM`) | SPM `from: "1.0.0"` | `Package.swift` |
| `otpless-iOS-intelligence-sdk` (`OTPlessIntelligence`) | CocoaPods `'OtplessEventIO', '~> 1.0'` | `OTPlessIntelligence.podspec` |
| `otpless-iOS-intelligence-sdk` (`OTPlessIntelligence`) | SPM `from: "1.0.0"` | `Package.swift` |

**Read those constraints carefully. They are RANGES, not pins.** Unlike the Android
libraries in this family — which consumers pin to an exact version in
`libs.versions.toml` — every consumer here accepts any `1.x`. That means:

- there is **no bump commit** to review;
- a `1.x` release reaches a merchant's build on their next `pod install` /
  `swift package update`;
- **nobody looks at a diff in between.**

A tag is a deploy. Treat every release of this library as shipping directly to merchant
apps, because it does. If a change is breaking, it needs a **major** version — `~> 1.0`
will otherwise pick it up silently.

## Build & test

Requires Xcode / a Swift toolchain. Everything builds for the macOS host, so no
simulator is needed.

```bash
make gate     # THE gate — run this before every merge
make build    # swift build
make test     # swift test
make api-dump # regenerate api/public-surface.txt after an INTENTIONAL surface change
```

`make gate` is the single canonical definition of "verified" in this repo. It runs:

1. `swift build`
2. `swift test` — the XCTest suite under `Tests/OtplessEventIOTests/` (domain models and
   use cases)
3. `scripts/check-public-surface.sh` — diffs the compiled module's public symbol graph
   against the committed golden `api/public-surface.txt`

`.github/workflows/build-test.yml` restates the same recipe on every PR and every push to
`main`. **Change the `gate` target in the Makefile first**, then the workflow.

## The public-surface golden

`api/public-surface.txt` is produced by `xcrun swift-symbolgraph-extract` over the
**compiled module** — not by parsing source — so it also captures surface that comes from
protocol conformances and default arguments, not just from edited declarations. Each line
is `<access> <symbol-kind> <dotted path> :: <declaration>`, sorted. It deliberately
contains no USRs, file paths or source locations, so it is stable across machines and
toolchain patch releases.

**Never hand-edit the golden.** If a surface change is intentional:

1. Grep the iOS SDK and the iOS intelligence SDK for the symbol.
2. Record it in `CHANGELOG.md`, and decide the version bump with the `~> 1.0` range in
   mind — breaking changes need a major version.
3. `make api-dump`, and include the golden diff in the PR.

## Working rules

- **Worktree-driven development.** The primary checkout belongs to the human. Every
  independent task gets its own worktree:
  `git worktree add /tmp/otpless-event-io-ios-<task> <branch>` — work, commit and push
  from there, then `git worktree remove` it.
- Never push to `main`; everything goes through a PR that passes the gate.
- `Package.resolved` is intentionally gitignored — a library should not pin its
  consumers' transitive versions.
- This library has an Android counterpart, `otpless-event-io`, with an equivalent public
  surface. The workspace hub's `CLAUDE.md` (change-flow rule 2, Android ↔ iOS parity)
  applies: a contract or event-shape change on one platform is a parity event on the
  other.
