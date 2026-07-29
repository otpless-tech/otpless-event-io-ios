# Changelog

Consumers (`OtplessBM`, `OTPlessIntelligence`) depend on this library as
`'OtplessEventIO', '~> 1.0'` — an open range — so a release reaches merchant builds with
no bump commit and no review in between. Every merchant-visible change belongs here, in
particular **any change to the public surface recorded in `api/public-surface.txt`**, and
a breaking change requires a **major** version bump because `~> 1.0` would otherwise pick
it up silently.

This file was introduced alongside the verification gate; releases made before it are not
reconstructed here. Consult the git history for anything below `1.0.0`.

## Unreleased

- Added a verification gate (`make gate`): `swift build`, `swift test`, and a committed
  public-API golden (`api/public-surface.txt`) extracted from the compiled module's
  symbol graph and checked by `scripts/check-public-surface.sh`. Added CI
  (`.github/workflows/build-test.yml`).

## 1.0.0

Initial release. See git history.
