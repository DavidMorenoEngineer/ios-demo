# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
