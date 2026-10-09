import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/dialog_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../compose/models/post.dart';
import '../view_models/posts_view_model.dart';

class PostsScreen extends ConsumerWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsViewModelProvider);
    final vm = ref.read(postsViewModelProvider.notifier);

    return AppScaffold(
      appBar: const CustomAppBar(title: 'My posts'),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: posts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text(e.toString().replaceFirst('Exception: ', ''))),
              TextButton(onPressed: vm.refresh, child: const Text('Retry')),
            ],
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No posts yet.')),
                  ],
                )
              : _PostsList(items: items),
        ),
      ),
    );
  }
}

class _PostsList extends ConsumerWidget {
  final List<Post> items;

  const _PostsList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming =
        items
            .where(
              (p) =>
                  p.status == PostStatus.scheduled ||
                  p.status == PostStatus.publishing,
            )
            .toList()
          ..sort(
            (a, b) => (a.scheduledAt ?? a.createdAt).compareTo(
              b.scheduledAt ?? b.createdAt,
            ),
          );
    final failed = items.where((p) => p.status == PostStatus.failed).toList();
    final published = items
        .where((p) => p.status == PostStatus.published)
        .toList();

    // Timeline: scheduled posts grouped by day, in time order.
    final byDay = <DateTime, List<Post>>{};
    for (final p in upcoming) {
      final t = p.scheduledAt ?? p.createdAt;
      (byDay[DateTime(t.year, t.month, t.day)] ??= []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          const _Header('Scheduled'),
          for (final day in byDay.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Text(
                formatPostDay(context, day.key),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final p in day.value) _PostTile(post: p),
          ],
        ],
        if (failed.isNotEmpty) ...[
          const _Header('Failed'),
          for (final p in failed) _PostTile(post: p),
        ],
        if (published.isNotEmpty) ...[
          const _Header('Published'),
          for (final p in published) _PostTile(post: p),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String text;

  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _PostTile extends ConsumerWidget {
  final Post post;

  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(postsViewModelProvider.notifier);
    final isVideo = RegExp(
      r'\.(mp4|mov)$',
      caseSensitive: false,
    ).hasMatch(post.mediaUrl);

    // Timeline rows lead with the time and type; the rest lead with caption.
    final isUpcoming =
        post.status == PostStatus.scheduled ||
        post.status == PostStatus.publishing;
    final caption = post.caption.isEmpty ? _typeLabel(post.type) : post.caption;
    final String title = isUpcoming
        ? '${post.status == PostStatus.publishing ? 'Now' : formatPostTimeOfDay(context, post.scheduledAt!)}'
              ' · ${_typeLabel(post.type)}'
        : caption;
    final String subtitle = switch (post.status) {
      PostStatus.scheduled when post.lastError != null =>
        'Retry · ${post.lastError}',
      PostStatus.scheduled => caption,
      PostStatus.publishing => 'Publishing… $caption',
      PostStatus.published => formatPostTime(context, post.publishedAt!),
      PostStatus.failed => post.lastError ?? 'Failed',
      _ => '',
    };

    Future<void> confirmDelete() async {
      final scheduled = post.status == PostStatus.scheduled;
      final ok = await ref
          .read(dialogServiceProvider.notifier)
          .showConfirmation(
            title: scheduled ? 'Cancel this post?' : 'Delete this post?',
            message: scheduled
                ? "It won't be published."
                : 'It will be removed from PostPilot.',
            confirmText: scheduled ? 'Cancel post' : 'Delete',
          );
      if (ok) await vm.delete(post);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: isVideo
                ? const ColoredBox(
                    color: Colors.black,
                    child: Icon(Icons.movie_outlined, color: Colors.white70),
                  )
                : Image.network(
                    post.mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: post.status == PostStatus.failed
                ? AppColors.error
                : AppColors.textSecondary,
          ),
        ),
        trailing: switch (post.status) {
          PostStatus.scheduled ||
          PostStatus.failed => PopupMenuButton<VoidCallback>(
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => vm.publishNow(post),
                child: Text(
                  post.status == PostStatus.failed ? 'Retry' : 'Publish now',
                ),
              ),
              PopupMenuItem(
                value: confirmDelete,
                child: Text(
                  post.status == PostStatus.scheduled ? 'Cancel' : 'Delete',
                ),
              ),
            ],
          ),
          _ => null,
        },
      ),
    );
  }

  static String _typeLabel(PostType type) => switch (type) {
    PostType.reel => 'Reel',
    PostType.story => 'Story',
    PostType.carousel => 'Carousel',
    _ => 'Photo',
  };
}
