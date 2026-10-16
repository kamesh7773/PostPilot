import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/plan_item.dart';
import '../repositories/ai_repository.dart';

/// Full preview of an autopilot slot: its media as it will look on Instagram
/// and the caption, which the user can edit until the post goes out.
class PostPreviewScreen extends HookConsumerWidget {
  final PlanItem item;

  const PostPreviewScreen({super.key, required this.item});

  static const _titles = {
    'reel': 'Reel preview',
    'image': 'Post preview',
    'carousel': 'Carousel preview',
    'story': 'Story preview',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caption = useState(item.caption);
    final editing = useState(false);
    final saving = useState(false);
    final controller = useTextEditingController(text: item.caption);
    final repo = ref.read(aiRepositoryProvider);
    final dialog = ref.read(dialogServiceProvider.notifier);
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    final isStory = item.format == 'story';

    Future<void> save() async {
      final text = controller.text.trim();
      saving.value = true;
      final response = await repo.updatePlanItem(item.id, caption: text);
      if (!context.mounted) return;
      saving.value = false;
      if (!response.isSuccess) {
        dialog.showError(response.error!);
        return;
      }
      caption.value = text;
      editing.value = false;
      dialog.showSuccess('Caption updated.');
    }

    void cancel() {
      controller.text = caption.value;
      editing.value = false;
    }

    return AppScaffold(
      appBar: CustomAppBar(title: _titles[item.format] ?? 'Preview'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Media(item: item),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Caption', style: textTheme.titleMedium),
              const Spacer(),
              if (!isStory && item.isEditable && !editing.value)
                TextButton.icon(
                  onPressed: () => editing.value = true,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isStory)
            Text(
              "Instagram Stories don't have a caption.",
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else if (editing.value) ...[
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 6,
              maxLines: null,
              maxLength: 2200,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(hintText: 'Write a caption…'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving.value ? null : cancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Save',
                    height: 44,
                    isLoading: saving.value,
                    onPressed: save,
                  ),
                ),
              ],
            ),
          ] else
            SelectableText(
              caption.value.isEmpty ? 'No caption.' : caption.value,
              style: textTheme.bodyMedium,
            ),
          if (!isStory && !item.isEditable) ...[
            const SizedBox(height: 12),
            Text(
              "This post is already publishing or posted, so its caption can't change.",
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The slot's media at Instagram's shape: one photo, swipeable carousel
/// slides, a Story card, or the Reel playing.
class _Media extends HookWidget {
  final PlanItem item;

  const _Media({required this.item});

  @override
  Widget build(BuildContext context) {
    final page = useState(0);
    final colors = context.colorScheme;
    final urls = item.mediaUrls;
    final vertical = item.format == 'reel' || item.format == 'story';

    final Widget content;
    if (urls.isEmpty) {
      content = ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              item.isGenerating
                  ? 'AI is still creating this. Check back in a few minutes.'
                  : "The media isn't ready yet.",
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    } else if (item.format == 'reel') {
      content = _ReelPlayer(url: urls.first);
    } else {
      content = Stack(
        children: [
          PageView(
            onPageChanged: (i) => page.value = i,
            children: [
              for (final url in urls)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, _, _) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
                ),
            ],
          ),
          if (urls.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${page.value + 1}/${urls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      );
    }

    // Keep tall Stories and Reels on screen with room for the caption.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * (vertical ? 0.65 : 0.55),
      child: Center(
        child: AspectRatio(
          aspectRatio: vertical ? 9 / 16 : 4 / 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _ReelPlayer extends HookWidget {
  final String url;

  const _ReelPlayer({required this.url});

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(
      () => VideoPlayerController.networkUrl(Uri.parse(url)),
      [url],
    );
    useEffect(() => controller.dispose, [controller]);
    final init = useMemoized(
      () => controller.initialize().then((_) {
        if (!context.mounted) return;
        controller
          ..setLooping(true)
          ..play();
      }),
      [controller],
    );
    final loaded = useFuture(init);
    final value = useValueListenable(controller);

    if (loaded.hasError) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            "Couldn't load the video.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    if (!value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return GestureDetector(
      onTap: () => value.isPlaying ? controller.pause() : controller.play(),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            if (!value.isPlaying)
              const Icon(
                Icons.play_circle_fill,
                size: 64,
                color: Colors.white,
                semanticLabel: 'Play',
              ),
          ],
        ),
      ),
    );
  }
}
