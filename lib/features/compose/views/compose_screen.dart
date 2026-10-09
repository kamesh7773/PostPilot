import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/dialog_service.dart';
import '../../ai/models/plan_item.dart';
import '../../ai/repositories/ai_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../social_accounts/models/social_account.dart';
import '../../social_accounts/view_models/social_accounts_view_model.dart';
import '../services/reel_video.dart';
import '../view_models/compose_state.dart';
import '../view_models/compose_view_model.dart';

const _maxCaptionLength = 2200;

class ComposeScreen extends HookConsumerWidget {
  /// Opened from the AI plan: pre-fills type, caption and time.
  final PlanItem? planItem;

  const ComposeScreen({super.key, this.planItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(composeViewModelProvider);
    final vm = ref.read(composeViewModelProvider.notifier);
    final accounts = ref
        .watch(socialAccountsViewModelProvider)
        .accounts
        .where((a) => a.status == SocialAccountStatus.active)
        .toList();

    final captionController = useTextEditingController(text: planItem?.caption);
    useListenable(captionController);
    useEffect(() {
      // After the first frame: providers can't change during build.
      if (planItem != null) Future.microtask(() => vm.applyPlan(planItem!));
      return null;
    }, const []);

    final isReel = state.kind == MediaKind.reel;

    return PopScope(
      canPop: state.canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && state.step == ComposeStep.publishing) {
          ref
              .read(dialogServiceProvider.notifier)
              .showInfo('Publishing continues in the background.');
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: AppScaffold(
          appBar: CustomAppBar(
            title: planItem == null ? 'Create post' : 'Fill your slot',
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<MediaKind>(
                // Labels only: four segments with icons don't fit a phone.
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: MediaKind.photo, label: Text('Photo')),
                  ButtonSegment(value: MediaKind.reel, label: Text('Reel')),
                  ButtonSegment(value: MediaKind.story, label: Text('Story')),
                  ButtonSegment(
                    value: MediaKind.carousel,
                    label: Text('Carousel'),
                  ),
                ],
                selected: {state.kind},
                onSelectionChanged: state.isBusy
                    ? null
                    : (selection) => vm.setKind(selection.first),
              ),
              const SizedBox(height: 16),
              if (planItem != null) ...[
                _PlanBanner(item: planItem!),
                const SizedBox(height: 16),
              ],
              if (accounts.length > 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: state.accountId,
                  decoration: const InputDecoration(labelText: 'Post to'),
                  items: [
                    for (final a in accounts)
                      DropdownMenuItem(
                        value: a.id,
                        child: Text('@${a.username}'),
                      ),
                  ],
                  onChanged: state.isBusy
                      ? null
                      : (id) => id == null ? null : vm.selectAccount(id),
                ),
                const SizedBox(height: 16),
              ] else if (accounts.length == 1) ...[
                Text(
                  'Posting to @${accounts.first.username}',
                  style: TextStyle(color: context.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
              ],
              _MediaBox(
                state: state,
                onPick: () {
                  // Close the keyboard (and any open text menu) before the
                  // picker covers the screen.
                  FocusManager.instance.primaryFocus?.unfocus();
                  vm.pickMedia();
                },
                onRemove: vm.removeMedia,
                onRemoveItem: vm.removeCarouselItem,
              ),
              if (state.kind == MediaKind.carousel) ...[
                const SizedBox(height: 8),
                const _Hint(
                  icon: Icons.info_outline,
                  text:
                      '2 to 10 photos or videos. Instagram crops every item to '
                      'the shape of the first one.',
                ),
              ],
              if (!isReel && state.wasCropped) ...[
                const SizedBox(height: 8),
                const _Hint(
                  icon: Icons.crop,
                  text:
                      'Cropped to fit Instagram (between 4:5 portrait and '
                      '1.91:1 landscape). The preview shows what will be posted.',
                ),
              ],
              const SizedBox(height: 16),
              if (state.kind == MediaKind.story)
                const _Hint(
                  icon: Icons.info_outline,
                  text:
                      'Stories are published as-is: Instagram does not allow '
                      'captions, stickers, links or music through its API.',
                )
              else
                TextField(
                  controller: captionController,
                  enabled: !state.isBusy,
                  maxLines: 6,
                  minLines: 3,
                  maxLength: _maxCaptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Caption',
                    hintText: 'Write a caption… #hashtags welcome',
                    alignLabelWithHint: true,
                  ),
                ),
              if (state.kind != MediaKind.story)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Write with AI'),
                    onPressed: state.isBusy
                        ? null
                        : () => _writeWithAi(
                            context,
                            ref,
                            state,
                            captionController,
                          ),
                  ),
                ),
              if (isReel)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Also share to feed'),
                  subtitle: const Text(
                    'Show this Reel on your profile grid, not just the Reels tab.',
                  ),
                  value: state.shareToFeed,
                  onChanged: state.isBusy ? null : vm.setShareToFeed,
                ),
              _ScheduleTile(
                scheduledAt: state.scheduledAt,
                enabled: !state.isBusy,
                onChanged: vm.setSchedule,
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: _buttonText(state),
                icon: state.scheduledAt == null
                    ? Icons.send_rounded
                    : Icons.schedule_send_outlined,
                isLoading: state.isBusy,
                onPressed: state.canPublish
                    ? () => vm.publish(captionController.text)
                    : null,
              ),
              if (state.isBusy) ...[
                const SizedBox(height: 12),
                _ProgressStatus(state: state),
              ],
              if (accounts.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Connect an Instagram account on the Home screen first.',
                  style: TextStyle(color: context.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Asks what the post is about, then fills the caption from the AI.
  static Future<void> _writeWithAi(
    BuildContext context,
    WidgetRef ref,
    ComposeState state,
    TextEditingController caption,
  ) async {
    final topicController = TextEditingController(text: caption.text);
    final topic = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('What is this post about?'),
        content: TextField(
          controller: topicController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. 5-minute beginner home workout',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, topicController.text.trim()),
            child: const Text('Write'),
          ),
        ],
      ),
    );
    if (topic == null || topic.isEmpty || !context.mounted) return;

    final dialog = ref.read(dialogServiceProvider.notifier);
    dialog.showInfo('Writing your caption…');
    final result = await ref
        .read(aiRepositoryProvider)
        .caption(
          type: switch (state.kind) {
            MediaKind.photo => 'image',
            MediaKind.reel => 'reel',
            MediaKind.story => 'story',
            MediaKind.carousel => 'carousel',
          },
          topic: topic,
        );
    if (!context.mounted) return;
    if (result.isSuccess) {
      caption.text = result.data!.full;
    } else if (result.statusCode == 409) {
      dialog.showError('Set up your creator profile on the Home screen first.');
    } else {
      dialog.showError(result.error!, title: "Couldn't write caption");
    }
  }

  static String _buttonText(ComposeState state) => switch (state.step) {
    ComposeStep.preparing => 'Preparing…',
    ComposeStep.uploading => 'Uploading…',
    ComposeStep.publishing => 'Publishing…',
    ComposeStep.idle when state.scheduledAt != null => 'Schedule',
    ComposeStep.idle => switch (state.kind) {
      MediaKind.photo => 'Publish now',
      MediaKind.reel => 'Publish Reel',
      MediaKind.story => 'Publish Story',
      MediaKind.carousel => 'Publish carousel',
    },
  };
}

class _ProgressStatus extends StatelessWidget {
  final ComposeState state;

  const _ProgressStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final percent = state.progress == null
        ? ''
        : ' ${(state.progress! * 100).clamp(0, 100).round()}%';
    final text = switch (state.step) {
      ComposeStep.preparing =>
        state.progress != null
            ? 'Preparing video for Instagram…$percent'
            : 'Preparing photo…',
      ComposeStep.uploading => 'Uploading…$percent',
      ComposeStep.publishing =>
        state.video != null
            ? 'Instagram is processing your video. This can take a few minutes '
                  '— you can leave this screen.'
            : 'Publishing to Instagram…',
      ComposeStep.idle => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: state.progress),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(color: context.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaBox extends StatelessWidget {
  final ComposeState state;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final ValueChanged<int> onRemoveItem;

  const _MediaBox({
    required this.state,
    required this.onPick,
    required this.onRemove,
    required this.onRemoveItem,
  });

  static final _radius = BorderRadius.circular(20);

  @override
  Widget build(BuildContext context) {
    if (state.kind == MediaKind.carousel && state.items.isNotEmpty) {
      return _CarouselStrip(
        state: state,
        onAdd: onPick,
        onRemoveItem: onRemoveItem,
      );
    }

    if (state.step == ComposeStep.preparing && !state.hasMedia) {
      return _frame(
        context,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!state.hasMedia) {
      return InkWell(
        onTap: state.isBusy ? null : onPick,
        borderRadius: _radius,
        child: _frame(
          context,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                switch (state.kind) {
                  MediaKind.photo => Icons.add_photo_alternate_outlined,
                  MediaKind.reel => Icons.video_library_outlined,
                  MediaKind.story => Icons.perm_media_outlined,
                  MediaKind.carousel => Icons.view_carousel_outlined,
                },
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(switch (state.kind) {
                MediaKind.photo => 'Choose a photo',
                MediaKind.reel => 'Choose a video',
                MediaKind.story => 'Choose a photo or video',
                MediaKind.carousel => 'Choose 2 to 10 photos or videos',
              }),
              const SizedBox(height: 4),
              Text(
                switch (state.kind) {
                  MediaKind.photo => 'Square, portrait (4:5) or landscape',
                  MediaKind.reel =>
                    '3 seconds to 15 minutes · vertical 9:16 works best',
                  MediaKind.story => 'Full-screen vertical 9:16 works best',
                  MediaKind.carousel => 'Square or portrait (4:5) work best',
                },
                style: TextStyle(
                  color: context.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final preview = state.video != null
        ? _VideoPreview(video: state.video!)
        // Not cropped by the widget, so the preview matches what's posted.
        : Image.file(
            File(state.imagePath!),
            width: double.infinity,
            fit: BoxFit.fitWidth,
          );

    return Stack(
      children: [
        ClipRRect(borderRadius: _radius, child: preview),
        if (!state.isBusy)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _OverlayButton(icon: Icons.swap_horiz, onTap: onPick),
                const SizedBox(width: 8),
                _OverlayButton(icon: Icons.close, onTap: onRemove),
              ],
            ),
          ),
      ],
    );
  }

  Widget _frame(BuildContext context, {required Widget child}) => Ink(
    height: 220,
    decoration: BoxDecoration(
      color: context.colorScheme.surface,
      borderRadius: _radius,
      border: Border.all(color: context.colorScheme.outlineVariant),
    ),
    child: child,
  );
}

class _VideoPreview extends StatelessWidget {
  final PreparedVideo video;

  const _VideoPreview({required this.video});

  @override
  Widget build(BuildContext context) {
    final minutes = video.duration.inMinutes;
    final seconds = (video.duration.inSeconds % 60).toString().padLeft(2, '0');
    final sizeMb = (video.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return SizedBox(
      height: 360,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          if (video.thumbnailPath != null)
            Image.file(File(video.thumbnailPath!), fit: BoxFit.contain),
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white70,
              size: 56,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '$minutes:$seconds · ${video.quality.label} · $sizeMb MB',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _CarouselStrip extends StatelessWidget {
  final ComposeState state;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveItem;

  const _CarouselStrip({
    required this.state,
    required this.onAdd,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = state.items.length < maxCarouselItems;
    final radius = BorderRadius.circular(14);

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.items.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return InkWell(
              onTap: state.isBusy ? null : onAdd,
              borderRadius: radius,
              child: Ink(
                width: 120,
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: radius,
                  border: Border.all(color: context.colorScheme.outlineVariant),
                ),
                child: state.step == ComposeStep.preparing
                    ? const Center(child: CircularProgressIndicator())
                    : const Icon(Icons.add, color: AppColors.primary, size: 32),
              ),
            );
          }

          final item = state.items[index];
          final thumb = item.video?.thumbnailPath ?? item.imagePath;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: radius,
                child: Container(
                  width: 120,
                  color: Colors.black,
                  child: thumb == null
                      ? null
                      : Image.file(File(thumb), fit: BoxFit.cover, height: 160),
                ),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
              if (item.video != null)
                const Positioned.fill(
                  child: Icon(Icons.play_circle_outline, color: Colors.white70),
                ),
              if (!state.isBusy)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _OverlayButton(
                    icon: Icons.close,
                    onTap: () => onRemoveItem(index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// "When to publish": now, or a date and time the user picks.
class _ScheduleTile extends StatelessWidget {
  final DateTime? scheduledAt;
  final bool enabled;
  final ValueChanged<DateTime?> onChanged;

  const _ScheduleTile({
    required this.scheduledAt,
    required this.enabled,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      // The backend accepts up to 75 days ahead.
      lastDate: now.add(const Duration(days: 75)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!picked.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a time in the future.')),
      );
      return;
    }
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: const Icon(Icons.schedule_outlined),
      title: const Text('When'),
      subtitle: Text(
        scheduledAt == null
            ? 'Publish now'
            : formatPostTime(context, scheduledAt!),
      ),
      trailing: scheduledAt == null
          ? const Text('Schedule')
          : IconButton(
              tooltip: 'Publish now instead',
              icon: const Icon(Icons.close),
              onPressed: enabled ? () => onChanged(null) : null,
            ),
      onTap: () => _pick(context),
    );
  }
}

/// What the AI planned for this slot, so the user knows what to shoot.
class _PlanBanner extends StatelessWidget {
  final PlanItem item;

  const _PlanBanner({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: context.textTheme.titleSmall),
                if (item.hook.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hook: ${item.hook}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
