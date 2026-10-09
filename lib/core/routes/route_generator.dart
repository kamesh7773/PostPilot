import 'package:flutter/material.dart';

import '../../features/auth/views/login_screen.dart';
import '../../features/compose/views/compose_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/posts/views/posts_screen.dart';
import 'routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case Routes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );

      case Routes.compose:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ComposeScreen(),
        );

      case Routes.posts:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PostsScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
