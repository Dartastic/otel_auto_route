# otel_auto_route

OpenTelemetry instrumentation for
[`package:auto_route`](https://pub.dev/packages/auto_route).

`OTelAutoRouterObserver` is a real `AutoRouterObserver` subclass —
not just a `NavigatorObserver`. In a tabbed auto_route app
(`AutoTabsRouter` / `AutoTabsScaffold`), switching tabs does not push
or pop a `Navigator` route, so a plain `NavigatorObserver` never
fires and every tab switch is a silently lost view. auto_route
delivers tab transitions through `didInitTabRoute` /
`didChangeTabRoute`, which only an `AutoRouterObserver` receives —
this package emits spans for them.

```dart
MaterialApp.router(
  routerConfig: _appRouter.config(
    navigatorObservers: () => [OTelAutoRouterObserver()],
  ),
);
```

`navigatorObservers` is a factory because every nested router (each
`AutoRouter`, each tabs router) calls it again — returning a new
instance per navigator is the supported auto_route pattern; all
instances emit through the same tracer.

## Span shape

One zero-length span per transition, ended immediately — a view
marker, so a trace waterfall reads as a user journey:

| Event | Span name | `navigation.action` |
|---|---|---|
| `didPush` | `route.push:<path>` | `push` |
| `didPop` | `route.pop:<path>` | `pop` |
| `didReplace` | `route.replace:<new-path>` | `replace` |
| `didRemove` | `route.remove:<path>` | `remove` |
| `didInitTabRoute` (a tab activates for the first time) | `route.tab_init:<path>` | `tab_init` |
| `didChangeTabRoute` (the user switches tabs) | `route.tab_change:<path>` | `tab_change` |

Spans carry `navigation.route.path` and, when present,
`navigation.previous_route_path`; the very first push also carries
`navigation.is_initial_route = true`. Tab spans use the route
*pattern* (so span names stay low-cardinality); tab roots with an
empty path fall back to the route name.

Span names and attribute keys are wire-identical to the sibling
[`otel_go_router`](https://pub.dev/packages/otel_go_router)
integration, so a mixed go_router + auto_route codebase produces one
uniform trace vocabulary — without either package depending on the
other.

## Configuration

`tracer`, `spanNameBuilder` (stack transitions only),
`recordArguments` (default `false` — arguments often carry user
data), `argumentAttributeMaxLength`.

## Caveats

- The observer calls `OTel.tracerProvider().getTracer(...)` in its
  constructor — `OTel.initialize()` must have already run.

## License

Apache 2.0
