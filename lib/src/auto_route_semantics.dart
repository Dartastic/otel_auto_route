// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Navigation attribute keys emitted by this package.
///
/// The key strings are byte-identical to the ones sibling router
/// integrations (e.g. `package:otel_go_router`) emit, so route spans
/// keep one wire vocabulary no matter which router a codebase uses.
/// They are declared here rather than imported because competing
/// router packages must not depend on each other — the shared wire
/// contract is the strings, pinned by test, not a shared symbol.
///
/// No `NavigationSemantics` enum ships in a published
/// `package:dartastic_opentelemetry_api` release yet; fold these back
/// into the API once navigation semantics ship upstream.
enum AutoRouteSemantics implements OTelSemantic {
  /// The navigation transition, e.g. `push`, `pop`, `replace`,
  /// `remove`, `tab_init`, `tab_change`.
  navigationAction('navigation.action'),

  /// Path of the route being navigated to.
  routePath('navigation.route.path'),

  /// Path of the route being navigated away from.
  previousRoutePath('navigation.previous_route_path'),

  /// Stringified arguments passed to the route.
  routeArguments('navigation.route.arguments'),

  /// `true` only on the very first navigation push (cold start).
  /// Lets you slice metrics by initial vs. in-session navigation.
  ///
  /// Candidate for upstreaming alongside the keys above
  /// (proposed key: `navigation.is_initial_route`).
  isInitialRoute('navigation.is_initial_route');

  const AutoRouteSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}
