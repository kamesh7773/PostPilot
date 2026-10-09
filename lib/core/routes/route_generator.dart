import 'package:flutter/material.dart';

import '../../features/ai/models/plan_item.dart';
import '../../features/ai/views/plan_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/compose/views/compose_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/posts/views/posts_screen.dart';
import '../../features/profile/views/profile_setup_screen.dart';
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
          builder: (_) =>
              ComposeScreen(planItem: settings.arguments as PlanItem?),
        );

      case Routes.posts:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PostsScreen(),
        );

      case Routes.profileSetup:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileSetupScreen(),
        );
      case Routes.plan:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PlanScreen(),
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
