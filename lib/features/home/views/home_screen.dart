import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../social_accounts/views/widgets/social_accounts_section.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

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

    return AppScaffold(
      appBar: CustomAppBar(
        title: AppConstants.appName,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: confirmSignOut,
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
                children: [
                  _Welcome(email: response.data!.email),
                  const SizedBox(height: 32),
                  const SocialAccountsSection(),
                ],
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

    return Row(
      children: [
        const Icon(
          Icons.rocket_launch_outlined,
          size: 40,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: textTheme.titleLarge),
              Text(
                email,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
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
              style: const TextStyle(color: AppColors.textSecondary),
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
