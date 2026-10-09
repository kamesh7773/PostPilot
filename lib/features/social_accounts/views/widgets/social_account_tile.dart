import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/social_account.dart';

class SocialAccountTile extends StatelessWidget {
  final SocialAccount account;
  final VoidCallback onDisconnect;
  final VoidCallback onReconnect;

  const SocialAccountTile({
    super.key,
    required this.account,
    required this.onDisconnect,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final needsReauth = account.status == SocialAccountStatus.needsReauth;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _Avatar(url: account.profilePictureUrl),
        title: Text(
          '@${account.username}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          needsReauth ? 'Reconnect needed' : account.displayName ?? 'Instagram',
          style: TextStyle(
            color: needsReauth
                ? AppColors.warning
                : context.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<VoidCallback>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) => action(),
          itemBuilder: (_) => [
            if (needsReauth)
              PopupMenuItem(value: onReconnect, child: const Text('Reconnect')),
            PopupMenuItem(value: onDisconnect, child: const Text('Disconnect')),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;

  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      backgroundColor: context.colorScheme.outlineVariant,
      child: Icon(
        Icons.camera_alt_outlined,
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
    if (url == null) return fallback;

    // Instagram CDN URLs expire; fall back quietly when they do.
    return ClipOval(
      child: Image.network(
        url!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
