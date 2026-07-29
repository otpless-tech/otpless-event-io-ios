.PHONY: build test api-dump surface-check gate clean

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

build:
	swift build

test:
	swift test

# Regenerate the committed public-API golden. Review the resulting diff — it is
# exactly what a consumer of the next release would see.
api-dump:
	bash scripts/check-public-surface.sh --update

surface-check:
	bash scripts/check-public-surface.sh

# THE GATE — the single canonical definition of "verified" for this repo.
# CLAUDE.md and .github/workflows/build-test.yml restate this recipe; change it HERE
# first. Nothing may be merged to main that has not passed `make gate`.
#
#   swift build             : compiles the library
#   swift test              : the repo's XCTest suite (domain models + use cases)
#   check-public-surface.sh : diffs the compiled module's public symbol graph against
#                             api/public-surface.txt. This library is consumed as
#                             'OtplessEventIO', '~> 1.0' — an OPEN RANGE — so a public
#                             surface change in any 1.x release reaches merchant builds
#                             on the next `pod install`, with no review in between.
gate:
	swift build
	swift test
	bash scripts/check-public-surface.sh

clean:
	swift package clean
	rm -rf .build
