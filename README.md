# otel_auto_route

OpenTelemetry instrumentation for
[`package:auto_route`](https://pub.dev/packages/auto_route).

```dart
AutoRouter.config(
  navigatorObservers: () => [OTelAutoRouterObserver()],
  routes: [...],
);
```

`OTelAutoRouterObserver` is a typedef alias for
`OTelGoRouterObserver` from
[`otel_go_router`](https://pub.dev/packages/otel_go_router).
auto_route drives a standard Flutter `Navigator`, so the same
generic `NavigatorObserver` works. This package exists so users
searching pub.dev for "auto_route OpenTelemetry" find it
directly — and so one package add gets you observability on an
auto_route app.

For span shape and configuration options, see the
`otel_go_router` README.

## License

Apache 2.0
