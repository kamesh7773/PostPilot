import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/services/dialog_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../models/social_account.dart';
import '../../view_models/social_accounts_view_model.dart';
import 'social_account_tile.dart';

/// "Connected accounts" block: lists accounts and offers Connect Instagram.
class SocialAccountsSection extends ConsumerWidget {
  const SocialAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialAccountsViewModelProvider);
    final vm = ref.read(socialAccountsViewModelProvider.notifier);

    Future<void> confirmDisconnect(SocialAccount account) async {
      final confirmed = await ref
          .read(dialogServiceProvider.notifier)
          .showConfirmation(
            title: 'Disconnect @${account.username}?',
            message:
                'PostPilot will stop publishing to this account. '
                'You can reconnect it any time.',
            confirmText: 'Disconnect',
          );
      if (confirmed) await vm.disconnect(account.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Connected accounts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (state.isLoading && state.accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null && state.accounts.isEmpty)
          _LoadError(message: state.error!, onRetry: vm.load)
        else ...[
          if (state.accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Connect your Instagram professional account to start '
                'scheduling and publishing.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          for (final account in state.accounts) ...[
            SocialAccountTile(
              account: account,
              onDisconnect: () => confirmDisconnect(account),
              onReconnect: vm.connectInstagram,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          CustomButton(
            text: state.accounts.isEmpty
                ? 'Connect Instagram'
                : 'Connect another account',
            icon: Icons.add_link,
            isLoading: state.isConnecting,
            onPressed: vm.connectInstagram,
          ),
        ],
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
