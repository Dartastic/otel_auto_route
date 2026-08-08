// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:auto_route/auto_route.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/widgets.dart';

import 'auto_route_semantics.dart';

/// OpenTelemetry instrumentation for `package:auto_route`.
///
/// An [AutoRouterObserver] subclass — **not** a plain
/// [NavigatorObserver]. That distinction is the whole point: in a
/// tabbed auto_route app (`AutoTabsRouter` / `AutoTabsScaffold`),
/// switching tabs does **not** push or pop a `Navigator` route, so a
/// plain `NavigatorObserver` never fires and every tab switch is a
/// silently lost view. auto_route delivers those transitions through
/// [didInitTabRoute] / [didChangeTabRoute], which only an
/// `AutoRouterObserver` receives.
///
/// Install through the router config's observer factory:
///
/// ```dart
/// MaterialApp.router(
///   routerConfig: _appRouter.config(
///     navigatorObservers: () => [OTelAutoRouterObserver()],
///   ),
/// );
/// ```
///
/// Nested routers (each `AutoRouter` / tabs router) call the
/// `navigatorObservers` factory again, which is why it is a factory —
/// returning a new instance per navigator is the supported pattern
/// and each instance emits through the same tracer.
///
/// ## Span shape
///
/// One zero-length span per transition, ended immediately — a view
/// marker, so a trace waterfall reads as a user journey:
///
/// | Event | Span name | `navigation.action` |
/// |---|---|---|
/// | `didPush` | `route.push:<path>` | `push` |
/// | `didPop` | `route.pop:<path>` | `pop` |
/// | `didReplace` | `route.replace:<new-path>` | `replace` |
/// | `didRemove` | `route.remove:<path>` | `remove` |
/// | `didInitTabRoute` | `route.tab_init:<path>` | `tab_init` |
/// | `didChangeTabRoute` | `route.tab_change:<path>` | `tab_change` |
///
/// Span names and attribute keys are wire-identical to the sibling
/// `package:otel_go_router` integration (see [AutoRouteSemantics]),
/// so a mixed go_router + auto_route codebase produces one uniform
/// trace vocabulary — without either package depending on the other.
///
/// Spans carry `navigation.route.path` and, when present,
/// `navigation.previous_route_path`. Tab spans use the route
/// *pattern* (so names stay low-cardinality); tab roots with an
/// empty path fall back to the route name. The very first `didPush`
/// also carries `navigation.is_initial_route = true`.
final class OTelAutoRouterObserver extends AutoRouterObserver {
  /// Creates an observer.
  ///
  /// - [tracer] — defaults to
  ///   `OTel.tracerProvider().getTracer('otel_auto_route')`.
  /// - [spanNameBuilder] — overrides the span name for *stack*
  ///   transitions. Useful for substituting `/orders/42` →
  ///   `/orders/:id` when `Route.settings.name` carries a resolved
  ///   URL. The default is `route.<transition>:<settings.name>`,
  ///   falling back to `<unnamed>`.
  /// - [recordArguments] — when `true`, stack-transition spans also
  ///   record `Route.settings.arguments.toString()`. Off by default
  ///   because arguments often carry user data.
  /// - [argumentAttributeMaxLength] — cap on the arguments attribute.
  OTelAutoRouterObserver({
    Tracer? tracer,
    String Function(String transition, Route<dynamic> route)? spanNameBuilder,
    this.recordArguments = false,
    this.argumentAttributeMaxLength = 256,
  })  : _tracer = tracer ?? OTel.tracerProvider().getTracer('otel_auto_route'),
        _spanNameBuilder = spanNameBuilder ?? _defaultSpanName;

  final Tracer _tracer;
  final String Function(String transition, Route<dynamic> route)
      _spanNameBuilder;

  /// When `true`, stack-transition spans record
  /// `Route.settings.arguments.toString()`.
  final bool recordArguments;

  /// Maximum length of the arguments attribute.
  final int argumentAttributeMaxLength;

  /// `true` until the very first `didPush` fires.
  bool _isFirstPush = true;

  static String _defaultSpanName(String transition, Route<dynamic> route) {
    final path = route.settings.name ?? '<unnamed>';
    return 'route.$transition:$path';
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emitStack(
      transition: 'push',
      route: route,
      previousRoute: previousRoute,
      isInitial: _isFirstPush,
    );
    _isFirstPush = false;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _emitStack(transition: 'pop', route: route, previousRoute: previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute == null) return;
    _emitStack(transition: 'replace', route: newRoute, previousRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _emitStack(
        transition: 'remove',
        route: route,
        previousRoute: previousRoute,
      );

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) =>
      _emitTab('tab_init', route, previousRoute);

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) =>
      _emitTab('tab_change', route, previousRoute);

  void _emitStack({
    required String transition,
    required Route<dynamic> route,
    required Route<dynamic>? previousRoute,
    bool isInitial = false,
  }) {
    final attrs = <String, Object>{
      AutoRouteSemantics.navigationAction.key: transition,
    };

    final path = route.settings.name;
    if (path != null) {
      attrs[AutoRouteSemantics.routePath.key] = path;
    }

    final prevPath = previousRoute?.settings.name;
    if (prevPath != null) {
      attrs[AutoRouteSemantics.previousRoutePath.key] = prevPath;
    }

    if (isInitial) {
      attrs[AutoRouteSemantics.isInitialRoute.key] = true;
    }

    if (recordArguments) {
      final args = route.settings.arguments;
      if (args != null) {
        attrs[AutoRouteSemantics.routeArguments.key] = _clip(args.toString());
      }
    }

    final span = _tracer.startSpan(
      _spanNameBuilder(transition, route),
      attributes: OTel.attributesFromMap(attrs),
    );
    span.end();
  }

  void _emitTab(
    String transition,
    TabPageRoute route,
    TabPageRoute? previousRoute,
  ) {
    final path = _tabPath(route);
    final attrs = <String, Object>{
      AutoRouteSemantics.navigationAction.key: transition,
      AutoRouteSemantics.routePath.key: path,
    };

    final prevPath = previousRoute == null ? null : _tabPath(previousRoute);
    if (prevPath != null) {
      attrs[AutoRouteSemantics.previousRoutePath.key] = prevPath;
    }

    final span = _tracer.startSpan(
      'route.$transition:$path',
      attributes: OTel.attributesFromMap(attrs),
    );
    span.end();
  }

  /// The route *pattern* keeps cardinality low; tab roots with an
  /// empty path fall back to the route name.
  static String _tabPath(TabPageRoute route) =>
      route.path.isNotEmpty ? route.path : route.name;

  String _clip(String s) {
    if (s.length <= argumentAttributeMaxLength) return s;
    return '${s.substring(0, argumentAttributeMaxLength)}…';
  }
}
