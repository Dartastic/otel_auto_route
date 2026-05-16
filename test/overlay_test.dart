// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_auto_route/otel_auto_route.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await OTel.reset();
    await OTel.initialize(
      serviceName: 'auto-route-otel-test',
      detectPlatformResources: false,
    );
  });

  tearDown(() async {
    await OTel.shutdown();
    await OTel.reset();
  });

  test('OTelAutoRouterObserver is an OTelGoRouterObserver typedef', () {
    final observer = OTelAutoRouterObserver();
    expect(observer, isA<OTelGoRouterObserver>());
  });
}
