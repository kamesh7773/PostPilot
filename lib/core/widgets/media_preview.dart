import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:video_player/video_player.dart';

import '../extensions/context_extensions.dart';

/// A post's media at Instagram's shape: one photo, swipeable carousel
/// slides, a Story card, or the Reel playing. [emptyText] shows until there is media.
class MediaPreview extends HookWidget {
  final String format;
  final List<String> urls;
  final String emptyText;

  const MediaPreview({
    super.key,
    required this.format,
    required this.urls,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final vertical = format == 'reel' || format == 'story';

    final Widget content;
    if (urls.isEmpty) {
      content = ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    } else if (format == 'reel') {
      content = _ReelPlayer(url: urls.first);
    } else {
      content = _Slides(
        urls: urls,
        onOpen: (i) => showDialog<void>(
          context: context,
          barrierColor: Colors.black87,
          builder: (dialog) => Stack(
            children: [
              Positioned.fill(
                child: _Slides(urls: urls, initialPage: i, fullScreen: true),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _RoundButton(
                  icon: Icons.close,
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(dialog).pop(),
                ),
              ),
            ],
          ),
        ),
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

/// Photos to page through by swipe, mouse drag (web doesn't drag a PageView by
/// default) or arrows. Tapping one calls [onOpen]; [fullScreen] shows them whole.
class _Slides extends HookWidget {
  final List<String> urls;
  final int initialPage;
  final bool fullScreen;
  final ValueChanged<int>? onOpen;

  const _Slides({
    required this.urls,
    this.initialPage = 0,
    this.fullScreen = false,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final controller = usePageController(initialPage: initialPage);
    final page = useState(initialPage);
    void go(int i) => controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );

    return Stack(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(
            context,
          ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
          child: PageView(
            controller: controller,
            onPageChanged: (i) => page.value = i,
            children: [
              for (final (i, url) in urls.indexed)
                GestureDetector(
                  onTap: onOpen == null ? null : () => onOpen!(i),
                  child: MouseRegion(
                    cursor: onOpen == null
                        ? MouseCursor.defer
                        : SystemMouseCursors.zoomIn,
                    child: Image.network(
                      url,
                      fit: fullScreen ? BoxFit.contain : BoxFit.cover,
                      semanticLabel: 'Image ${i + 1} of ${urls.length}',
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (urls.length > 1) ...[
          if (page.value > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Previous',
                  onPressed: () => go(page.value - 1),
                ),
              ),
            ),
          if (page.value < urls.length - 1)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _RoundButton(
                  icon: Icons.chevron_right,
                  tooltip: 'Next',
                  onPressed: () => go(page.value + 1),
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton.filled(
    icon: Icon(icon),
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black54,
      foregroundColor: Colors.white,
    ),
  );
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.only(top: 12),
              ),
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
