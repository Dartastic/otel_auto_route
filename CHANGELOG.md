# Changelog

## [0.2.0-wip]

## [0.1.0] - 2026-08-08

### Added

- `OTelAutoRouterObserver` — a real `AutoRouterObserver` subclass
  (previously a typedef alias for a plain `NavigatorObserver`). The
  subclass receives auto_route's `didInitTabRoute` /
  `didChangeTabRoute` callbacks and emits `route.tab_init:<path>` /
  `route.tab_change:<path>` spans with `navigation.action` and
  `navigation.route.path` (+ `navigation.previous_route_path`) — tab
  switches in `AutoTabsRouter` apps are no longer silently lost
  views. Stack transitions (push / pop / replace / remove) emit
  `route.<transition>:<path>` spans of the same shape.
- `AutoRouteSemantics` — typed `navigation.*` attribute keys, pinned
  by a wire-format test. Key strings are wire-identical to the
  sibling `otel_go_router` integration, so a mixed go_router +
  auto_route codebase produces one uniform trace vocabulary.

### Changed

- Decoupled from `otel_go_router`: the dependency (and its
  path `dependency_override` + publish-order chain) is gone —
  competing routers must not be coupled, and auto_route users no
  longer transitively install go_router. The shared route semantics
  are inlined as `AutoRouteSemantics`; the wire contract is the key
  strings, pinned by test, not a shared symbol.
- Raised SDK floor to `dartastic_opentelemetry ^1.1.0-beta.12`.
- Widened `auto_route` to `>=9.0.0 <12.0.0` (analyze + tests green
  against both 9.0.0 and 11.1.0).
