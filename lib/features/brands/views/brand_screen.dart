import 'dart:async';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/routes.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../social_accounts/models/social_account.dart';
import '../../social_accounts/view_models/social_accounts_view_model.dart';
import '../models/brand.dart';
import '../models/brand_post.dart';
import '../repositories/brands_repository.dart';

/// Live QR: where it posts, a new post, and its posts. The AI already knows Live QR
/// (the backend has its brief built in).
class BrandScreen extends HookConsumerWidget {
  final Brand initial;

  const BrandScreen({super.key, required this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = useState(initial);
    final posts = useState<List<BrandPost>?>(null);
    final repo = ref.read(brandsRepositoryProvider);
    final dialog = ref.read(dialogServiceProvider.notifier);
    final navigation = ref.read(navigationServiceProvider.notifier);
    final accounts = ref.watch(socialAccountsViewModelProvider);
    final accountsVm = ref.read(socialAccountsViewModelProvider.notifier);

    Future<void> loadBrand() async {
      final response = await repo.fetchBrands();
      if (!context.mounted || !response.isSuccess) return;
      for (final b in response.data!) {
        if (b.id == brand.value.id) brand.value = b;
      }
    }

    Future<void> loadPosts() async {
      final response = await repo.fetchPosts(brand.value.id);
      if (!context.mounted) return;
      if (response.isSuccess) {
        posts.value = response.data;
      } else {
        posts.value ??= const [];
        dialog.showError(response.error!);
      }
    }

    useEffect(() {
      loadPosts();
      return null;
    }, const []);

    // Keep statuses fresh while the AI is working or a post is going out.
    final busy =
        posts.value?.any((p) => p.isGenerating || p.isPublishing) ?? false;
    useEffect(() {
      if (!busy) return null;
      final timer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => loadPosts(),
      );
      return timer.cancel;
    }, [busy]);

    Future<void> pickAccount(String? id) async {
      final response = await repo.setAccount(brand.value.id, id);
      if (!context.mounted) return;
      if (!response.isSuccess) return dialog.showError(response.error!);
      brand.value = response.data!;
      dialog.showSuccess('Account updated.');
    }

    // Reconnecting also saves the Facebook Page's token, which Facebook posting needs.
    Future<void> connect() async {
      await accountsVm.connectInstagram();
      if (context.mounted) await loadBrand();
    }

    Future<void> open(BrandPost post) async {
      await navigation.pushNamed(
        Routes.brandPost,
        arguments: (post: post, brand: brand.value),
      );
      if (context.mounted) await loadPosts();
    }

    return AppScaffold(
      appBar: CustomAppBar(title: '${brand.value.name} posts'),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([loadBrand(), loadPosts()]),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _AccountCard(
              brand: brand.value,
              accounts: accounts.accounts,
              connecting: accounts.isConnecting,
              onPick: pickAccount,
              onConnect: connect,
            ),
            const SizedBox(height: 16),
            _NewPostCard(
              ready: brand.value.account != null,
              onCreate: (format, idea) async {
                final response = await repo.createPost(
                  brand.value.id,
                  format: format,
                  idea: idea,
                );
                if (!context.mounted) return false;
                if (!response.isSuccess) {
                  dialog.showError(response.error!);
                  return false;
                }
                posts.value = [response.data!, ...?posts.value];
                return true;
              },
            ),
            const SizedBox(height: 16),
            _UploadCard(
              ready: brand.value.account != null,
              onUpload: (format, caption, files) async {
                final response = await repo.createOwnPost(
                  brand.value.id,
                  format: format,
                  caption: caption,
                  files: files,
                );
                if (!context.mounted) return false;
                if (!response.isSuccess) {
                  dialog.showError(response.error!);
                  return false;
                }
                posts.value = [response.data!, ...?posts.value];
                unawaited(open(response.data!));
                return true;
              },
            ),
            const SizedBox(height: 24),
            Text('Posts', style: context.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (posts.value == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (posts.value!.isEmpty)
              Text(
                'No posts yet. Make one above.',
                style: TextStyle(color: context.colorScheme.onSurfaceVariant),
              )
            else
              for (final post in posts.value!)
                _PostTile(post: post, onTap: () => open(post)),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Brand brand;
  final List<SocialAccount> accounts;
  final bool connecting;
  final ValueChanged<String?> onPick;
  final VoidCallback onConnect;

  const _AccountCard({
    required this.brand,
    required this.accounts,
    required this.connecting,
    required this.onPick,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final account = brand.account;
    final muted = TextStyle(color: context.colorScheme.onSurfaceVariant);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Posts to', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: account?.id,
              isExpanded: true,
              hint: const Text('Choose the Instagram account'),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id, child: Text('@${a.username}')),
              ],
              onChanged: onPick,
            ),
            const SizedBox(height: 12),
            if (account != null && account.needsReconnect)
              _Note(
                icon: Icons.error_outline,
                color: AppColors.error,
                text: 'Instagram access expired. Reconnect the account.',
              )
            else if (account != null && account.canPostToFacebook)
              _Note(
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                text:
                    'Each post also goes to the Facebook Page '
                    '"${account.facebookPageName ?? 'linked to this account'}".',
              )
            else if (account != null)
              _Note(
                icon: Icons.info_outline,
                color: AppColors.warning,
                text:
                    'Reconnect this account to also post to its Facebook Page, '
                    'and allow "Manage posts" when Facebook asks.',
              )
            else
              Text(
                'Pick the Live QR Instagram account. Its linked Facebook Page '
                'gets the same posts.',
                style: muted,
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: connecting ? null : onConnect,
              icon: const Icon(Icons.add_link),
              label: Text(
                connecting
                    ? 'Connecting…'
                    : account == null
                    ? 'Connect an account'
                    : 'Reconnect accounts',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPostCard extends HookWidget {
  final bool ready;
  final Future<bool> Function(String format, String idea) onCreate;

  const _NewPostCard({required this.ready, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final format = useState('image');
    final idea = useTextEditingController();
    final creating = useState(false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New post', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                for (final entry in BrandPost.labels.entries)
                  ButtonSegment(value: entry.key, label: Text(entry.value)),
              ],
              selected: {format.value},
              // Room for all four labels on one line on a phone.
              showSelectedIcon: false,
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              onSelectionChanged: (v) => format.value = v.first,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idea,
              minLines: 2,
              maxLines: 5,
              maxLength: 150000,
              decoration: const InputDecoration(
                hintText:
                    'What should it be about? (optional, e.g. "restaurants '
                    'updating their menu without reprinting")',
              ),
            ),
            CustomButton(
              text: ready ? 'Create with AI' : 'Choose an account first',
              icon: Icons.auto_awesome,
              isLoading: creating.value,
              onPressed: ready
                  ? () async {
                      creating.value = true;
                      final ok = await onCreate(format.value, idea.text.trim());
                      if (!context.mounted) return;
                      creating.value = false;
                      if (ok) idea.clear();
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'You review it before anything is posted. A Reel takes a few minutes.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _Upload = ({String name, Uint8List bytes});

/// Your own files instead of AI: drop or choose them, write the caption, then review.
/// The backend fits them to the format (4:5 posts, 9:16 Stories and Reels).
class _UploadCard extends HookWidget {
  final bool ready;
  final Future<bool> Function(
    String format,
    String caption,
    List<_Upload> files,
  )
  onUpload;

  const _UploadCard({required this.ready, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final format = useState('image');
    final files = useState<List<_Upload>>(const []);
    final caption = useTextEditingController();
    final hovering = useState(false);
    final uploading = useState(false);
    final muted = TextStyle(color: context.colorScheme.onSurfaceVariant);

    Future<void> add(
      Iterable<({String name, Future<Uint8List> bytes})> picked,
    ) async {
      final usable = picked.where(
        (f) => uploadExtensions.contains(f.name.split('.').last.toLowerCase()),
      );
      if (usable.length < picked.length && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use JPG, PNG or WebP images, or MP4 or MOV videos.'),
          ),
        );
      }
      final added = [
        for (final f in usable) (name: f.name, bytes: await f.bytes),
      ];
      if (added.isEmpty) return;
      final video = added.where((f) => isVideoFile(f.name)).firstOrNull;
      // A Reel is one video; otherwise images add up, 10 at most.
      files.value = video != null
          ? [video]
          : [
              ...files.value.where((f) => !isVideoFile(f.name)),
              ...added,
            ].take(10).toList();
      format.value = formatFor([
        for (final f in files.value) f.name,
      ], format.value);
    }

    Future<void> choose() async {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: uploadExtensions,
      );
      await add([
        for (final f in picked) (name: f.name, bytes: f.readAsBytes()),
      ]);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Post your own', style: context.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Already made it? Drop your image(s) or video here. No AI.',
              style: muted,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                for (final entry in BrandPost.labels.entries)
                  ButtonSegment(value: entry.key, label: Text(entry.value)),
              ],
              selected: {format.value},
              showSelectedIcon: false,
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              onSelectionChanged: (v) => format.value = v.first,
            ),
            const SizedBox(height: 12),
            DropTarget(
              onDragEntered: (_) => hovering.value = true,
              onDragExited: (_) => hovering.value = false,
              onDragDone: (details) {
                hovering.value = false;
                add([
                  for (final f in details.files)
                    (name: f.name, bytes: f.readAsBytes()),
                ]);
              },
              child: InkWell(
                onTap: choose,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: hovering.value
                        ? context.colorScheme.primary.withValues(alpha: .08)
                        : null,
                    border: Border.all(
                      color: hovering.value
                          ? context.colorScheme.primary
                          : context.colorScheme.outlineVariant,
                      width: hovering.value ? 2 : 1,
                    ),
                  ),
                  child: files.value.isEmpty
                      ? Column(
                          children: [
                            const Icon(Icons.upload_file, size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Drag files here, or click to choose',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '1 image = Post or Story · 2-10 images = Carousel '
                              '· 1 video = Reel. Sizes are fixed for you.',
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodySmall?.merge(muted),
                            ),
                          ],
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final f in files.value)
                              _Thumb(
                                file: f,
                                onRemove: () {
                                  files.value = [
                                    for (final o in files.value)
                                      if (o != f) o,
                                  ];
                                  format.value = formatFor([
                                    for (final o in files.value) o.name,
                                  ], format.value);
                                },
                              ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (format.value != 'story')
              TextField(
                controller: caption,
                minLines: 3,
                maxLines: 10,
                maxLength: 2200,
                decoration: const InputDecoration(
                  hintText:
                      'Caption (liveqr.maxaix.com is added for you if '
                      'it\'s missing)',
                ),
              ),
            CustomButton(
              text: ready ? 'Upload and review' : 'Choose an account first',
              icon: Icons.upload,
              isLoading: uploading.value,
              onPressed: ready && files.value.isNotEmpty
                  ? () async {
                      uploading.value = true;
                      final ok = await onUpload(
                        format.value,
                        caption.text.trim(),
                        files.value,
                      );
                      if (!context.mounted) return;
                      uploading.value = false;
                      if (ok) {
                        files.value = const [];
                        caption.clear();
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'You approve it before anything is posted.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.merge(muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final _Upload file;
  final VoidCallback onRemove;

  const _Thumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 88,
          child: isVideoFile(file.name)
              ? ColoredBox(
                  color: context.colorScheme.surfaceContainerHighest,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie_outlined),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          file.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                )
              : Image.memory(file.bytes, fit: BoxFit.cover),
        ),
      ),
      Positioned(
        top: 2,
        right: 2,
        child: IconButton.filledTonal(
          tooltip: 'Remove',
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ),
    ],
  );
}

class _PostTile extends StatelessWidget {
  final BrandPost post;
  final VoidCallback onTap;

  const _PostTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (text, color) = statusOf(post);
    final title = post.caption.isNotEmpty
        ? post.caption.split('\n').first
        : post.idea.isNotEmpty
        ? post.idea
        : post.label;
    final thumb = post.format != 'reel' && post.mediaUrls.isNotEmpty
        ? post.mediaUrls.first
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 48,
            child: thumb == null
                ? ColoredBox(
                    color: context.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      post.format == 'reel'
                          ? Icons.movie_outlined
                          : Icons.image_outlined,
                    ),
                  )
                : Image.network(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${post.label} · $text',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// A short status line for a post, and its colour.
(String, Color) statusOf(BrandPost post) {
  if (post.isGenerating) {
    return (
      post.own
          ? 'Preparing your files…'
          : post.mediaUrls.isEmpty
          ? 'AI is making it…'
          : 'Making your change…',
      AppColors.info,
    );
  }
  if (post.isFailed) return ('Couldn\'t make it', AppColors.error);
  if (post.inReview) return ('Waiting for your approval', AppColors.warning);
  if (post.isPublishing) return ('Posting…', AppColors.info);
  if (post.publishFailed) return ('Posting failed', AppColors.error);
  return ('Posted', AppColors.success);
}

class _Note extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Note({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(text)),
    ],
  );
}
