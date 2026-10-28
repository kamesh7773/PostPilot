import 'package:postpilot/core/config/env.dart';
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

  testWidgets('Live QR posts open only in the dev flavor', (tester) async {
    Future<String?> brandsRoute(Environment flavor) async {
      await Env.init(flavor);
      return RouteGenerator.generateRoute(
        const RouteSettings(name: Routes.brands),
      ).settings.name;
    }

    expect(await brandsRoute(Environment.production), isNot(Routes.brands));
    expect(await brandsRoute(Environment.staging), isNot(Routes.brands));
    expect(await brandsRoute(Environment.development), Routes.brands);

    // A web reload reopens the URL without its data: those pages open their list.
    String? reopen(String name) =>
        RouteGenerator.generateRoute(RouteSettings(name: name)).settings.name;
    expect(reopen(Routes.brandPost), Routes.brands);
    expect(reopen(Routes.planPreview), Routes.plan);
  });
}
