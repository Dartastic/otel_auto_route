// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:auto_route/auto_route.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_auto_route/otel_auto_route.dart';

/// In-memory span exporter so tests can assert what was emitted.
class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

Route<void> _route(String? name, {Object? arguments}) =>
    MaterialPageRoute<void>(
      settings: RouteSettings(name: name, arguments: arguments),
      builder: (_) => const SizedBox(),
    );

TabPageRoute _tab(String name, String path, int index) => TabPageRoute(
      routeInfo: RouteMatch<void>(
        config: AutoRoute(
          page: PageInfo(name, builder: (_) => const SizedBox()),
          path: path,
        ),
        segments: [path],
        stringMatch: path,
        key: ValueKey(name),
      ),
      index: index,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoRouteSemantics', () {
    test('keys are the documented wire format', () {
      // The deliberate literal comparisons: these key strings ARE the
      // wire contract shared with sibling router integrations (e.g.
      // otel_go_router) — the packages are decoupled on purpose, so
      // only this pin keeps route spans identical across routers.
      expect(AutoRouteSemantics.navigationAction.key, 'navigation.action');
      expect(AutoRouteSemantics.routePath.key, 'navigation.route.path');
      expect(
        AutoRouteSemantics.previousRoutePath.key,
        'navigation.previous_route_path',
      );
      expect(
        AutoRouteSemantics.routeArguments.key,
        'navigation.route.arguments',
      );
      expect(
        AutoRouteSemantics.isInitialRoute.key,
        'navigation.is_initial_route',
      );
    });
  });

  late _MemorySpanExporter exporter;
  late OTelAutoRouterObserver observer;

  setUp(() async {
    await OTel.reset();
    exporter = _MemorySpanExporter();
    await OTel.initialize(
      serviceName: 'auto-route-otel-test',
      detectPlatformResources: false,
      spanProcessor: SimpleSpanProcessor(exporter),
    );
    observer = OTelAutoRouterObserver();
  });

  tearDown(() async {
    await OTel.shutdown();
    await OTel.reset();
  });

  test('is an AutoRouterObserver, so auto_route delivers tab events', () {
    // The old typedef alias was only a NavigatorObserver — tabbed
    // apps silently lost every tab switch.
    expect(observer, isA<AutoRouterObserver>());
  });

  test('didInitTabRoute emits a tab_init span with the route pattern',
      () async {
    observer.didInitTabRoute(_tab('HomeTab', 'home', 0), null);

    expect(exporter.spans, hasLength(1));
    final span = exporter.spans.single;
    expect(span.name, equals('route.tab_init:home'));
    final attrs = _attrs(span);
    expect(attrs['navigation.action'], equals('tab_init'));
    expect(attrs['navigation.route.path'], equals('home'));
    expect(attrs.containsKey('navigation.previous_route_path'), isFalse);
  });

  test('didChangeTabRoute emits a tab_change span with previous path',
      () async {
    observer.didChangeTabRoute(
      _tab('SettingsTab', 'settings', 1),
      _tab('HomeTab', 'home', 0),
    );

    expect(exporter.spans, hasLength(1));
    final span = exporter.spans.single;
    expect(span.name, equals('route.tab_change:settings'));
    final attrs = _attrs(span);
    expect(attrs['navigation.action'], equals('tab_change'));
    expect(attrs['navigation.route.path'], equals('settings'));
    expect(attrs['navigation.previous_route_path'], equals('home'));
  });

  test('empty-path tab root falls back to the route name', () async {
    observer.didInitTabRoute(_tab('RootTab', '', 0), null);

    expect(exporter.spans.single.name, equals('route.tab_init:RootTab'));
  });

  test('didPush emits a push span; only the first push is initial', () async {
    observer.didPush(_route('/users/:id'), null);

    expect(exporter.spans, hasLength(1));
    final first = exporter.spans.single;
    expect(first.name, equals('route.push:/users/:id'));
    final firstAttrs = _attrs(first);
    expect(firstAttrs['navigation.action'], equals('push'));
    expect(firstAttrs['navigation.route.path'], equals('/users/:id'));
    expect(firstAttrs['navigation.is_initial_route'], equals(true));

    observer.didPush(_route('/orders'), _route('/users/:id'));

    expect(exporter.spans, hasLength(2));
    final second = _attrs(exporter.spans.last);
    expect(second['navigation.previous_route_path'], equals('/users/:id'));
    expect(second.containsKey('navigation.is_initial_route'), isFalse);
  });

  test('didPop / didReplace / didRemove emit their stack spans', () async {
    observer.didPop(_route('/orders'), _route('/'));
    observer.didReplace(newRoute: _route('/login'), oldRoute: _route('/'));
    observer.didRemove(_route('/stale'), _route('/'));

    expect(
      exporter.spans.map((s) => s.name),
      equals([
        'route.pop:/orders',
        'route.replace:/login',
        'route.remove:/stale',
      ]),
    );
    expect(_attrs(exporter.spans[0])['navigation.action'], equals('pop'));
    expect(_attrs(exporter.spans[1])['navigation.action'], equals('replace'));
    expect(_attrs(exporter.spans[2])['navigation.action'], equals('remove'));
    expect(
      _attrs(exporter.spans[1])['navigation.previous_route_path'],
      equals('/'),
    );
  });

  test('didReplace with a null newRoute emits nothing', () async {
    observer.didReplace(newRoute: null, oldRoute: _route('/'));

    expect(exporter.spans, isEmpty);
  });

  test('unnamed stack route falls back to <unnamed>', () async {
    observer.didPop(_route(null), null);

    expect(exporter.spans.single.name, equals('route.pop:<unnamed>'));
  });

  test('spanNameBuilder overrides stack span names', () async {
    final custom = OTelAutoRouterObserver(
      spanNameBuilder: (transition, route) =>
          'nav.$transition[${route.settings.name}]',
    );

    custom.didPush(_route('/users/:id'), null);

    expect(exporter.spans.single.name, equals('nav.push[/users/:id]'));
  });

  test('recordArguments: true captures clipped arguments', () async {
    final recording = OTelAutoRouterObserver(
      recordArguments: true,
      argumentAttributeMaxLength: 5,
    );

    recording.didPush(
      _route('/x', arguments: 'this string is long'),
      null,
    );

    final arg =
        _attrs(exporter.spans.single)['navigation.route.arguments']! as String;
    expect(arg, endsWith('…'));
    expect(arg.length, equals(6)); // 5 + ellipsis
  });

  test('arguments are off by default (often user data)', () async {
    observer.didPush(_route('/x', arguments: 'secret'), null);

    expect(
      _attrs(exporter.spans.single).containsKey('navigation.route.arguments'),
      isFalse,
    );
  });
}
