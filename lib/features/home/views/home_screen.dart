import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/routes.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/aurora.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../social_accounts/views/widgets/social_accounts_section.dart';
import '../../posts/view_models/posts_view_model.dart';
import '../../social_accounts/view_models/social_accounts_view_model.dart';
import '../repositories/home_repository.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Home is only shown when signed in: register this device for alerts,
    // explaining why first if we've never asked.
    useEffect(() {
      ref.read(pushServiceProvider.notifier).registerIfAllowed().then((ask) {
        if (ask && context.mounted) {
          ref
              .read(navigationServiceProvider.notifier)
              .pushNamed(Routes.notificationPermission);
        }
      });
      return null;
    }, const []);

    final currentUser = ref.watch(currentUserProvider);
    final profile = ref.watch(profileViewModelProvider);
    final navigation = ref.read(navigationServiceProvider.notifier);

    Future<void> confirmSignOut() async {
      final confirmed = await ref
          .read(dialogServiceProvider.notifier)
          .showConfirmation(
            title: 'Sign out?',
            message: 'You will need to sign in again to continue.',
            confirmText: 'Sign out',
          );
      if (!confirmed) return;
      await ref.read(authViewModelProvider.notifier).signOut();
    }

    Future<void> confirmReset() async {
      final dialog = ref.read(dialogServiceProvider.notifier);
      final confirmed = await dialog.showConfirmation(
        title: 'Reset account?',
        message:
            'This permanently deletes your connected Instagram accounts, '
            'scheduled posts, AI plan, creator profile and uploaded media. '
            'Posts already on Instagram stay there. You stay signed in.',
        confirmText: 'Reset',
      );
      if (!confirmed) return;
      dialog.showLoading();
      final response = await ref.read(homeRepositoryProvider).resetAccount();
      dialog.hideLoading();
      if (!response.isSuccess) {
        dialog.showError(response.error!, title: 'Reset failed');
        return;
      }
      ref
        ..invalidate(socialAccountsViewModelProvider)
        ..invalidate(profileViewModelProvider)
        ..invalidate(postsViewModelProvider)
        ..invalidate(currentUserProvider);
      dialog.showSuccess(
        'Your account is fresh again.',
        title: 'Account reset',
      );
    }

    return AppScaffold(
      appBar: CustomAppBar(
        title: AppConstants.appName,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Creator profile',
            onPressed: () => navigation.pushNamed(Routes.profileSetup),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'My posts',
            onPressed: () => ref
                .read(navigationServiceProvider.notifier)
                .pushNamed(Routes.posts),
          ),
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.dark_mode_outlined),
            tooltip: 'Theme',
            initialValue: ref.watch(themeModeControllerProvider),
            onSelected: ref.read(themeModeControllerProvider.notifier).set,
            itemBuilder: (_) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('System')),
              PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Account',
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: confirmReset,
                child: const ListTile(
                  leading: Icon(Icons.restart_alt, color: AppColors.error),
                  title: Text(
                    'Reset account',
                    style: TextStyle(color: AppColors.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: confirmSignOut,
                child: const ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: currentUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _BackendError(
          message: e.toString(),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (response) => response.isSuccess
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: Reveal.stagger([
                  _Welcome(email: response.data!.email),
                  const SizedBox(height: 20),
                  if (profile.hasValue && profile.value == null)
                    _SetupCard(
                      icon: Icons.person_outline,
                      title: 'Set up your creator profile',
                      body:
                          'Answer a few questions so Autocreator can suggest '
                          'what to post and when.',
                      action: 'Get started',
                      onTap: () => navigation.pushNamed(Routes.profileSetup),
                    )
                  else if (profile.value != null)
                    _SetupCard(
                      icon: Icons.auto_awesome,
                      title: 'Your AI weekly plan',
                      body:
                          'What to post and when for your '
                          '${profile.value!.niche.toLowerCase()} audience. '
                          'You just add the media.',
                      action: 'Open',
                      onTap: () => navigation.pushNamed(Routes.plan),
                    ),
                  const SizedBox(height: 32),
                  const SocialAccountsSection(),
                ]),
              )
            : _BackendError(
                message: response.error!,
                onRetry: () => ref.invalidate(currentUserProvider),
              ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final String email;

  const _Welcome({required this.email});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuroraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hey there 👋',
            style: textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'What are we posting today?',
            style: textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            email,
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _BackendError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BackendError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            const Text("Couldn't reach the backend"),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: context.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  const _SetupCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(body),
        trailing: TextButton(onPressed: onTap, child: Text(action)),
        onTap: onTap,
      ),
    );
  }
}
