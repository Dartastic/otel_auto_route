// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// OpenTelemetry instrumentation for `package:auto_route`.
///
/// auto_route drives a standard Flutter [Navigator] under the hood,
/// so the same `OTelGoRouterObserver` from `otel_go_router`
/// works as a generic [NavigatorObserver] — re-exported here as
/// `OTelAutoRouterObserver` for discoverability.
///
/// ```dart
/// AutoRouter.config(
///   navigatorObservers: () => [OTelAutoRouterObserver()],
///   ...
/// );
/// ```
library;

import 'package:otel_go_router/otel_go_router.dart';

export 'package:otel_go_router/otel_go_router.dart' show OTelGoRouterObserver;

/// Alias for [OTelGoRouterObserver] — the same `NavigatorObserver`
/// works for any Flutter router (`go_router`, `auto_route`,
/// `beamer`, hand-rolled).
typedef OTelAutoRouterObserver = OTelGoRouterObserver;
