# Changelog

## [0.1.0-beta.1-wip]

### Added

- `OTelAutoRouterObserver` — typedef alias for
  `OTelGoRouterObserver` from `dartastic_go_router_otel`. Since
  auto_route drives a standard Flutter `Navigator`, the existing
  generic `NavigatorObserver` works as-is; this package is a
  discoverability layer so users searching for "auto_route
  OpenTelemetry" find it.
- Bundles `auto_route` and `dartastic_go_router_otel` so one
  package add covers an auto_route app.
- Smoke test confirming the typedef + that the observer
  constructs against a real `OTel.tracerProvider()`.
