# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- iPhone and iPad demo videos (scripted UI-test tour recorded with `tool/record_demo.sh`), embedded in the README.
- `SideKixDemoUITests` target with the demo tour.

### Changed
- Clients are `@DependencyClient` structs; `testValue` is unimplemented, so tests must override what they use.
- Navigation uses `StackState` (iPhone) and `@Presents` (iPad) with a real `ProfileFeature` per open profile;
  advisors are stored once, and popping a profile cancels its toast timer.
- Demo launch options are Debug-only and are applied to the initial store state instead of inside the views.
- Presentation helpers (`Accent.color`, `Offer.symbol`) moved out of the domain model.
- More unit tests: deep link, selection, reload keeping the open profile, toast cancellation on pop.

### Fixed
- CI link failure (`Undefined symbol: IssueReporting…`): TCA's re-exported modules are now direct dependencies.
- Unit-test host app no longer calls unimplemented clients, which caused an intermittent test failure.

## [1.0.0] — 2026-10-14

### Added
- Native iOS app (SwiftUI) for the **Advisors** section of the SideKix site: a searchable, filterable advisor
  list and a full advisor profile.
- Adaptive layout for iPhone and iPad from one codebase: a navigation stack on compact width, a
  `NavigationSplitView` (list + profile) on regular width, and a profile that switches between one and two
  columns based on the width it is given.
- Full-screen, editorial presentation of an advisor profile, opened from the toolbar.
- The Composable Architecture: `AdvisorsFeature` and `ProfileFeature` reducers; `AdvisorsClient` and
  `BookingClient` dependency clients that hold all the mock data.
- `TestStore` tests that run against the mock clients (loading, failure and retry, search, filter, navigation,
  booking toast timing with a `TestClock`).
- iPhone 16 Pro and iPad Pro 13" screenshots, in portrait and landscape.
