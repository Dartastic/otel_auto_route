<!-- dartastic-header:start -->
# OpenTelemetry instrumentation for `auto_route`

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenTelemetry Specification](https://img.shields.io/badge/OpenTelemetry-Specification-blueviolet)](https://opentelemetry.io/docs/specs/otel/)

`otel_auto_route` is an [OpenTelemetry](https://opentelemetry.io/) instrumentation for `auto_route` that
easily adds standard observability to applications that use `auto_route`.  This package depends on 
[dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package can be used with any OTel backend because it's compliant with the OpenTelemetry Specification.

This package supports Android, iOS, Linux, macOS, Web and Windows, for versions of `auto_route` that support those platforms. It is WASM-ready.

This package is professionally maintained and supported with 💙 by Michael Bushe, Dart and Flutter Maintainer at OpenTelemetry
and the creator of [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry)
and [dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package is professionally maintained for the Dart and Flutter community and professionally supported by 
[Dartastic.io](https://dartastic.io).

---
## Dartastic.io: AI Code Healing and Real User Monitoring for Flutter

**See what your users experience. Find problems with Flutter apps in production. Fix them with AI.**

[Dartastic.io](https://dartastic.io) brings AI code healing, real user monitoring, and OpenTelemetry observability together in one platform built for Dart and Flutter. (Patents pending)

![Dartastic AI answering "Why did crashes jump after the last release?" over a Flutter App Health dashboard](https://dartastic.io/img/pub-dev/HomePageCrashesQuestion.png)

### Dartastic AI — From Production Problems to Code Fixes

Dartastic AI analyzes production telemetry alongside your application source code to diagnose problems and propose fixes.

- **Investigate production issues** using crashes, errors, traces, metrics, and real user telemetry.
- **Find the offending code** by connecting observed problems with your application's source in Dartastic Pub or your source code repos.
- **Generate code patches** that address the underlying problems.
- **Create actionable issues** in your issue tracker, complete with findings and the proposed code patch.

### Dartastic RUM — See What Your Users See

Understand how people actually experience your Flutter application.

- **Replay user sessions** in the Dartastic Observatory session player.
- **Choose your replay fidelity**, from privacy-preserving widget outlines to pixel-level reproductions of the user experience.
- **Investigate real user problems** using session replay and production observability data.

![Dartastic RUM Session Replay](https://dartastic.io/img/pub-dev/session-replay.png)

### Dartastic Observatory — Observability Built for Flutter

A complete observability backend where Flutter and Dart are first-class citizens.

- **Flutter-specific dashboards** for application performance, health, and reliability.
- **Alerts and notifications** through email, Slack, and PagerDuty.
- **Dartastic Cloud Observatory** — Start with a 30-day free trial on isolated, shared infrastructure, as low as $39/mo.
- **Dartastic Hosted Observatory** — Run the observability stack in a private managed environment, sized from Mini to Enterprise XL.
- **Dartastic Self-Hosted Observatory** — The whole platform inside your own network. Your keys, your cluster, with nothing leaving your perimeter.

### Dartastic Native OTel Runtime — Native OpenTelemetry Performance

Collect production telemetry without burdening Flutter's main isolate.

- **Native OpenTelemetry runtime** that moves telemetry processing off the main isolate.
- **Native crash reporting** for problems that Dart can't catch.
- **Widget performance diagnostics** to identify janky widgets.
- **On-device PII filtering** before sensitive data leaves your application.
- **Source-level error diagnostics** powered by the Dartastic Symbolizer API.
- **Platform-native metrics** for iOS, Android, and Linux, including iOS MetricKit and Android Vitals.
- **OpenTelemetry compatibility** — Send telemetry to Dartastic Observatory or any OpenTelemetry platform.

### Dartastic Labs — OpenTelemetry Integrations

Instrument more of your application without writing everything yourself.

- **650+ open-source integrations** for Dart and Flutter libraries and services, including Dio, Shelf, Logger, Anthropic, AWS, Azure, and Stripe. Look for otel_* on pub.dev.

### More Dartastic Tools

**[Dartastic Pub](https://dartastic.io/pub)**

A private Dart package registry for sharing packages and plugins with your team, partners, and customers.

**[Dartastic Symbolizer](https://dartastic.io/symbolizer)**

Turn production errors into lines of source code through a web API, while keeping your source code artifacts private.

### Professional Support and Training

Dartastic.io offers commercial support for the open-source `dartastic_opentelemetry` and `dartastic_opentelemetry_api` packages and the complete Dartastic product suite.

- **Professional support** with available around-the-clock coverage and response times under four hours on qualifying plans.
- **OpenTelemetry training** for teams instrumenting Dart, Flutter, mobile, and web applications.

### Open Standards. No Mandatory Backend.

The Dartastic OpenTelemetry API and SDK are open source and standards-based. You can use them independently of Dartastic's commercial services and send telemetry to any compatible OpenTelemetry backend.

Dartastic's commercial products add native performance, advanced diagnostics, session replay, AI-assisted remediation, and managed observability services.

**[Explore Dartastic.io](https://dartastic.io)**

---
<!-- dartastic-header:end -->

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
