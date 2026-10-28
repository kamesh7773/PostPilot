import 'package:flutter/material.dart';

import '../config/env.dart';

import '../../features/ai/models/plan_item.dart';
import '../../features/ai/views/plan_screen.dart';
import '../../features/ai/views/post_preview_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/brands/models/brand.dart';
import '../../features/brands/models/brand_post.dart';
import '../../features/brands/views/brand_post_screen.dart';
import '../../features/brands/views/brands_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/notifications/views/notification_permission_screen.dart';
import '../../features/posts/views/posts_screen.dart';
import '../../features/profile/views/profile_setup_screen.dart';
import 'routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Live QR posts exist only in the dev flavor; elsewhere its routes don't open.
    final devOnly = settings.name?.startsWith(Routes.brands) ?? false;
    switch (devOnly && !Env.isDevelopment ? null : settings.name) {
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
      case Routes.notificationPermission:
        return MaterialPageRoute(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => const NotificationPermissionScreen(),
        );

      case Routes.plan:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PlanScreen(),
        );
      case Routes.planPreview:
        // Same on reload: without the plan item, show the plan.
        final item = settings.arguments;
        return MaterialPageRoute(
          settings: item is PlanItem
              ? settings
              : const RouteSettings(name: Routes.plan),
          builder: (_) => item is PlanItem
              ? PostPreviewScreen(item: item)
              : const PlanScreen(),
        );

      case Routes.brands:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BrandsScreen(),
        );
      case Routes.brandPost:
        // A web reload or restart reopens the URL without the post: show the list instead.
        if (settings.arguments case (
          :final BrandPost post,
          :final Brand brand,
        )) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => BrandPostScreen(initial: post, brand: brand),
          );
        }
        return MaterialPageRoute(
          settings: const RouteSettings(name: Routes.brands),
          builder: (_) => const BrandsScreen(),
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
