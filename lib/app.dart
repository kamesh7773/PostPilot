import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

import 'core/config/env.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/route_generator.dart';
import 'core/routes/routes.dart';
import 'core/services/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/auth/repositories/auth_repository.dart';

class PostPilotApp extends ConsumerWidget {
  const PostPilotApp({super.key});

  String get _appTitle {
    if (Env.isDevelopment) return '${AppConstants.appName} Dev';
    if (Env.isStaging) return '${AppConstants.appName} Staging';
    return AppConstants.appName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.watch(navigationServiceProvider.notifier);
    final isSignedIn = ref.read(authRepositoryProvider).isSignedIn;
    final themeMode = ref.watch(themeModeControllerProvider);

    // Single place that reacts to auth changes: sign-in from the login
    // screen, sign-out from anywhere, or the session being revoked.
    ref.listen(authStateChangesProvider, (_, next) {
      switch (next.value?.event) {
        case AuthChangeEvent.signedIn:
          navigationService.pushNamedAndRemoveUntil(Routes.home);
        case AuthChangeEvent.signedOut:
          navigationService.pushNamedAndRemoveUntil(Routes.login);
        default:
          break;
      }
    });

    return ScreenUtilInit(
      designSize: const Size(
        AppConstants.designWidth,
        AppConstants.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MaterialApp(
          title: _appTitle,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigationService.navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          locale: const Locale('en', 'US'),
          initialRoute: isSignedIn ? Routes.home : Routes.login,
          // Push only the initial route. Flutter's default also pushes every
          // parent path, so '/login' would build Home ('/') underneath it.
          onGenerateInitialRoutes: (initialRoute) => [
            RouteGenerator.generateRoute(RouteSettings(name: initialRoute)),
          ],
          onGenerateRoute: RouteGenerator.generateRoute,
          builder: (context, child) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final iconBrightness = isDark ? Brightness.light : Brightness.dark;
            final content = ToastificationWrapper(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: iconBrightness,
                  statusBarBrightness: theme.brightness,
                  systemNavigationBarColor: theme.scaffoldBackgroundColor,
                  systemNavigationBarIconBrightness: iconBrightness,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );

            if (Env.isProduction) return content;

            return Banner(
              message: Env.isDevelopment ? 'DEV' : 'STAGING',
              location: BannerLocation.topEnd,
              color: Env.isDevelopment ? Colors.green : Colors.orange,
              child: content,
            );
          },
        );
      },
    );
  }
}
