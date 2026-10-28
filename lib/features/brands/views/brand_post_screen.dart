import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/media_preview.dart';
import '../models/brand.dart';
import '../models/brand_post.dart';
import '../repositories/brands_repository.dart';
import 'brand_screen.dart' show statusOf;

/// Review a brand post: see it, ask for changes as often as needed, and approve it.
/// Nothing is posted until the owner taps Approve.
class BrandPostScreen extends HookConsumerWidget {
  final BrandPost initial;
  final Brand brand;

  const BrandPostScreen({
    super.key,
    required this.initial,
    required this.brand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = useState(initial);
    final busy = useState(false);
    final note = useTextEditingController();
    final caption = useTextEditingController(text: initial.caption);
    final repo = ref.read(brandsRepositoryProvider);
    final dialog = ref.read(dialogServiceProvider.notifier);
    final p = post.value;
    // A new version (e.g. after an AI change) replaces what's in the box.
    useEffect(() {
      caption.text = p.caption;
      return null;
    }, [p.caption]);
    final captionEdited = useListenableSelector(
      caption,
      () => caption.text.trim() != p.caption.trim(),
    );

    Future<void> load() async {
      final response = await repo.fetchPost(p.id);
      if (context.mounted && response.isSuccess) post.value = response.data!;
    }

    // Follow the AI, then the publishing, until there's nothing left to wait for.
    final waiting = p.isGenerating || p.isPublishing;
    useEffect(() {
      if (!waiting) return null;
      final timer = Timer.periodic(const Duration(seconds: 8), (_) => load());
      return timer.cancel;
    }, [waiting]);

    Future<void> send(Future<dynamic> Function() call) async {
      busy.value = true;
      final response = await call();
      if (!context.mounted) return;
      busy.value = false;
      if (!response.isSuccess) return dialog.showError(response.error!);
      post.value = response.data!;
    }

    Future<void> requestChange() async {
      final text = note.text.trim();
      if (p.inReview && text.isEmpty) {
        return dialog.showInfo('Write what you would like changed.');
      }
      await send(() => repo.requestChange(p.id, text));
      if (context.mounted && post.value.isGenerating) note.clear();
    }

    Future<bool> saveCaption() async {
      busy.value = true;
      final response = await repo.updateCaption(p.id, caption.text.trim());
      if (!context.mounted) return false;
      busy.value = false;
      if (!response.isSuccess) {
        dialog.showError(response.error!);
        return false;
      }
      post.value = response.data!;
      return true;
    }

    Future<void> approve() async {
      // Post what's in the caption box, not the last saved version.
      if (captionEdited && !await saveCaption()) return;
      if (!context.mounted) return;
      final account = brand.account;
      final where = [
        'Instagram @${account?.username ?? ''}',
        if (account?.canPostToFacebook ?? false)
          'the Facebook Page "${account!.facebookPageName ?? ''}"',
      ].join(' and ');
      final confirmed = await dialog.showConfirmation(
        title: p.publishFailed ? 'Try posting again?' : 'Approve and post?',
        message: 'This posts it now to $where.',
        confirmText: p.publishFailed ? 'Try again' : 'Post it',
      );
      if (confirmed) await send(() => repo.approve(p.id));
    }

    Future<void> remove() async {
      final confirmed = await dialog.showConfirmation(
        title: 'Delete this post?',
        message: p.isApproved
            ? 'It stays on Instagram and Facebook; only this draft is removed.'
            : 'The draft and its images are discarded.',
        confirmText: 'Delete',
      );
      if (!confirmed) return;
      final response = await repo.deletePost(p.id);
      if (!context.mounted) return;
      if (!response.isSuccess) return dialog.showError(response.error!);
      Navigator.pop(context);
    }

    final (statusText, statusColor) = statusOf(p);
    final muted = TextStyle(color: context.colorScheme.onSurfaceVariant);

    return AppScaffold(
      appBar: CustomAppBar(
        title: '${brand.name} · ${p.label}',
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: p.isGenerating ? null : remove,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
          ),
          if (p.isGenerating) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 16),
          MediaPreview(
            format: p.format,
            urls: p.mediaUrls,
            emptyText: p.isFailed
                ? 'Nothing to show yet.'
                : p.own
                ? 'Preparing your files for Instagram and Facebook. '
                      'A video can take a minute.'
                : 'AI is making this ${p.label.toLowerCase()}. '
                      'A Reel can take a few minutes; you can leave this screen.',
          ),
          if (p.error != null) ...[
            const SizedBox(height: 16),
            _Banner(text: p.error!, color: AppColors.error),
          ],
          const SizedBox(height: 24),
          Text('Caption', style: context.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (p.inReview && p.format != 'story') ...[
            TextField(
              controller: caption,
              minLines: 3,
              maxLines: 12,
              maxLength: 2200,
            ),
            if (captionEdited)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: busy.value ? null : saveCaption,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save caption'),
                ),
              ),
          ] else
            SelectableText(
              p.format == 'story'
                  ? "Stories don't have a caption."
                  : p.caption.isEmpty
                  ? 'Not written yet.'
                  : p.caption,
              style: p.caption.isEmpty ? muted : null,
            ),
          if (p.idea.isNotEmpty || p.changeRequests.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('What you asked for', style: context.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (p.idea.isNotEmpty) Text('• ${p.idea}'),
            for (final change in p.changeRequests) Text('• $change'),
          ],
          if (p.isApproved) ...[
            const SizedBox(height: 24),
            _Destination(
              name: 'Instagram @${brand.account?.username ?? ''}',
              state: p.instagram,
            ),
            const SizedBox(height: 8),
            _Destination(name: 'Facebook Page', state: p.facebook),
            if (p.publishFailed) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'Try posting again',
                icon: Icons.refresh,
                isLoading: busy.value,
                onPressed: approve,
              ),
            ],
          ],
          if (p.own && p.isFailed) ...[
            const SizedBox(height: 16),
            Text(
              'Delete this post and upload the files again.',
              textAlign: TextAlign.center,
              style: muted,
            ),
          ],
          if (!p.own && (p.inReview || p.isFailed)) ...[
            const SizedBox(height: 24),
            Text(
              p.isFailed ? 'Try again' : 'Ask for changes',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: note,
              minLines: 2,
              maxLines: 6,
              maxLength: 150000,
              decoration: InputDecoration(
                hintText: p.isFailed
                    ? 'Anything to do differently? (optional)'
                    : 'e.g. "Make the caption shorter", "use a café photo", '
                          '"mention the 3 months free offer"',
              ),
            ),
            OutlinedButton.icon(
              onPressed: busy.value ? null : requestChange,
              icon: const Icon(Icons.auto_fix_high),
              label: Text(p.isFailed ? 'Try again' : 'Make these changes'),
            ),
          ],
          if (p.inReview) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: 'Approve and post',
              icon: Icons.check,
              isLoading: busy.value,
              onPressed: brand.account == null ? null : approve,
            ),
            if (brand.account == null) ...[
              const SizedBox(height: 8),
              Text(
                'Choose the brand\'s Instagram account first.',
                textAlign: TextAlign.center,
                style: muted,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Where the post stands on one platform.
class _Destination extends StatelessWidget {
  final String name;
  final PublishState? state;

  const _Destination({required this.name, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final (icon, color, text) = s == null || s.isBusy
        ? (Icons.schedule, AppColors.info, 'Posting…')
        : s.isDone
        ? (Icons.check_circle, AppColors.success, 'Posted')
        : (Icons.error_outline, AppColors.error, s.error ?? 'Posting failed');

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name),
        subtitle: s?.isDone == true && s?.permalink != null
            ? SelectableText(s!.permalink!)
            : Text(text),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color color;

  const _Banner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Text(text, style: TextStyle(color: color)),
  );
}
