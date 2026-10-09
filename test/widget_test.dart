import 'package:postpilot/core/routes/route_generator.dart';
import 'package:postpilot/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home is the initial route', () {
    final route = RouteGenerator.generateRoute(
      const RouteSettings(name: Routes.home),
    );

    expect(route, isA<MaterialPageRoute>());
    expect(route.settings.name, Routes.home);
  });
}
