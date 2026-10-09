import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../ai/models/plan_item.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/services/navigation_service.dart';
import '../../social_accounts/models/social_account.dart';
import '../../social_accounts/view_models/social_accounts_view_model.dart';
import '../models/post.dart';
import '../repositories/compose_repository.dart';
import '../services/instagram_image.dart';
import '../services/reel_video.dart';
import 'compose_state.dart';

part 'compose_view_model.g.dart';

const _pollInterval = Duration(seconds: 3);
// Reels can take several minutes to process on Instagram's side.
const _pollTimeout = Duration(minutes: 16);

@riverpod
class ComposeViewModel extends _$ComposeViewModel {
  // Plain field, not `state`: Riverpod forbids reading state in onDispose.
  bool _isEncoding = false;

  @override
  ComposeState build() {
    ref.onDispose(() {
      if (_isEncoding) cancelReelEncoding();
    });

    final accounts = ref.read(socialAccountsViewModelProvider).accounts;
    final active = accounts
        .where((a) => a.status == SocialAccountStatus.active)
        .toList();
    return ComposeState(accountId: active.isEmpty ? null : active.first.id);
  }

  ComposeRepository get _repo => ref.read(composeRepositoryProvider);
  DialogService get _dialog => ref.read(dialogServiceProvider.notifier);

  void selectAccount(String id) => state = state.copyWith(accountId: id);

  void setKind(MediaKind kind) {
    if (state.isBusy || kind == state.kind) return;
    state = state.copyWith(kind: kind);
  }

  void setShareToFeed(bool value) => state = state.copyWith(shareToFeed: value);

  /// null = publish now.
  void setSchedule(DateTime? when) => state = state.copyWith(scheduledAt: when);

  /// Pre-fills type and time from an AI plan slot. A slot whose time has
  /// passed publishes now unless the user picks a new time.
  void applyPlan(PlanItem item) {
    final when = item.when;
    state = state.copyWith(
      kind: switch (item.format) {
        'reel' => MediaKind.reel,
        'story' => MediaKind.story,
        'carousel' => MediaKind.carousel,
        _ => MediaKind.photo,
      },
      scheduledAt: when.isAfter(DateTime.now().add(const Duration(minutes: 2)))
          ? when
          : null,
      planItemId: item.id,
    );
  }

  void removeMedia() => state = state.copyWith(
    imagePath: null,
    wasCropped: false,
    video: null,
    items: const [],
  );

  void removeCarouselItem(int index) =>
      state = state.copyWith(items: [...state.items]..removeAt(index));

  Future<void> pickMedia() async {
    if (state.kind == MediaKind.carousel) return _addCarouselItems();

    final picker = ImagePicker();
    final XFile? picked = switch (state.kind) {
      MediaKind.photo => await picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      ),
      MediaKind.reel => await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: ReelVideoSpec.maxDuration,
      ),
      MediaKind.story => await picker.pickMedia(requestFullMetadata: false),
      MediaKind.carousel => null,
    };
    if (picked == null || !ref.mounted) return;

    // Replace whatever was picked before (a Story can switch photo ↔ video).
    removeMedia();
    if (_isVideo(picked)) {
      final video = await _prepareVideo(picked.path);
      if (video != null && ref.mounted) state = state.copyWith(video: video);
    } else {
      final photo = await _preparePhoto(
        picked.path,
        feed: state.kind != MediaKind.story,
      );
      if (photo != null && ref.mounted) {
        state = state.copyWith(
          imagePath: photo.path,
          wasCropped: photo.wasCropped,
        );
      }
    }
  }

  /// Adds photos/videos to the carousel (up to [maxCarouselItems] total),
  /// preparing each one like a feed photo or a Reel.
  Future<void> _addCarouselItems() async {
    final room = maxCarouselItems - state.items.length;
    if (room <= 0) return;

    // `limit` must be at least 2, so with one slot left we trim afterwards.
    final picked = await ImagePicker().pickMultipleMedia(
      limit: room < 2 ? null : room,
      requestFullMetadata: false,
    );
    if (!ref.mounted || picked.isEmpty) return;
    if (picked.length > room) {
      _dialog.showInfo('A carousel can have up to $maxCarouselItems items.');
    }

    for (final file in picked.take(room)) {
      final item = _isVideo(file)
          ? await _prepareVideo(
              file.path,
            ).then((v) => v == null ? null : CarouselItem.video(v))
          : await _preparePhoto(
              file.path,
            ).then((p) => p == null ? null : CarouselItem.photo(p.path));
      if (!ref.mounted) return;
      if (item != null) state = state.copyWith(items: [...state.items, item]);
    }
  }

  bool _isVideo(XFile file) =>
      file.mimeType?.startsWith('video/') ??
      RegExp(r'\.(mp4|mov|m4v)$', caseSensitive: false).hasMatch(file.path);

  Future<PreparedImage?> _preparePhoto(String path, {bool feed = true}) async {
    state = state.copyWith(step: ComposeStep.preparing, progress: null);
    final prepared = await prepareInstagramImage(
      path,
      feed: feed,
    ).catchError((Object _) => null);
    if (!ref.mounted) return null;
    state = state.copyWith(step: ComposeStep.idle);

    if (prepared == null) {
      _dialog.showError("This photo couldn't be prepared. Try another one.");
    }
    return prepared;
  }

  Future<PreparedVideo?> _prepareVideo(String path) async {
    state = state.copyWith(step: ComposeStep.preparing, progress: 0.0);
    try {
      final duration = await readReelDuration(path);
      return await _encode(path, duration: duration);
    } on ReelVideoException catch (e) {
      if (ref.mounted) _dialog.showError(e.message);
    } catch (_) {
      if (ref.mounted) {
        _dialog.showError("This video couldn't be prepared. Try another one.");
      }
    } finally {
      if (ref.mounted) state = state.copyWith(step: ComposeStep.idle);
    }
    return null;
  }

  Future<void> publish(String caption) async {
    if (!state.canPublish) return;

    final toUpload = state.kind == MediaKind.carousel
        ? state.items
        : [
            state.video != null
                ? CarouselItem.video(state.video!)
                : CarouselItem.photo(state.imagePath!),
          ];
    final mediaPaths = <String>[];
    for (final item in toUpload) {
      final path = item.video != null
          ? await _uploadVideo(item.video!)
          : await _uploadPhoto(item.imagePath!);
      if (path == null || !ref.mounted) return;
      mediaPaths.add(path);
    }

    final scheduledAt = state.scheduledAt;
    if (scheduledAt != null && scheduledAt.isBefore(DateTime.now())) {
      _fail('The scheduled time has passed. Pick a new time.');
      return;
    }

    state = state.copyWith(step: ComposeStep.publishing, progress: null);
    final created = await _repo.createPost(
      socialAccountId: state.accountId!,
      type: switch (state.kind) {
        MediaKind.photo => PostType.image,
        MediaKind.reel => PostType.reel,
        MediaKind.story => PostType.story,
        MediaKind.carousel => PostType.carousel,
      },
      mediaPaths: mediaPaths,
      // Stories have no caption.
      caption: state.kind == MediaKind.story ? '' : caption.trim(),
      shareToFeed: state.shareToFeed,
      scheduledAt: scheduledAt,
      planItemId: state.planItemId,
      timezone: scheduledAt == null
          ? null
          : await FlutterTimezone.getLocalTimezone()
                .then((tz) => tz.identifier)
                .catchError((Object _) => ''),
    );
    if (!ref.mounted) return;
    if (!created.isSuccess) {
      _fail(created.error!);
      return;
    }

    // Scheduled: the backend publishes it at that time, nothing to wait for.
    if (scheduledAt != null) {
      state = state.copyWith(step: ComposeStep.idle);
      _dialog.showSuccess(
        "It will publish automatically, even if your phone is off.",
        title: 'Scheduled',
      );
      ref.read(navigationServiceProvider.notifier).pop();
      return;
    }

    final post = await _waitForResult(created.data!);
    if (!ref.mounted) return;
    state = state.copyWith(step: ComposeStep.idle);

    switch (post?.status) {
      case PostStatus.published:
        _dialog.showSuccess(switch (state.kind) {
          MediaKind.photo => 'Your post is live on Instagram.',
          MediaKind.reel => 'Your Reel is live on Instagram.',
          MediaKind.story => 'Your Story is live on Instagram.',
          MediaKind.carousel => 'Your carousel is live on Instagram.',
        }, title: 'Published');
        ref.read(navigationServiceProvider.notifier).pop();
      case PostStatus.failed:
        _dialog.showError(
          post!.lastError ?? 'Instagram rejected this post.',
          title: 'Publish failed',
        );
      default:
        _dialog.showInfo(
          "Instagram is still processing. It will publish when it's ready.",
          title: 'Still processing',
        );
    }
  }

  Future<String?> _uploadPhoto(String imagePath) async {
    state = state.copyWith(step: ComposeStep.uploading, progress: null);
    final upload = await _repo.uploadImage(
      imagePath,
      story: state.kind == MediaKind.story,
    );
    if (!ref.mounted) return null;
    if (!upload.isSuccess) {
      _fail(upload.error!, title: 'Upload failed');
      return null;
    }
    return upload.data;
  }

  /// Uploads an encoded video; re-encodes at a lower quality once if it's
  /// over the server's size limit.
  Future<String?> _uploadVideo(PreparedVideo video) async {
    while (true) {
      state = state.copyWith(step: ComposeStep.uploading, progress: 0.0);
      try {
        final slot = await _repo.requestVideoUpload(sizeBytes: video.sizeBytes);
        if (!ref.mounted) return null;
        if (!slot.isSuccess) {
          _fail(slot.error!, title: 'Upload failed');
          return null;
        }

        final uploaded = await _repo.uploadVideo(
          slot.data!,
          video.path,
          onProgress: _setProgress,
        );
        if (!ref.mounted) return null;
        if (!uploaded.isSuccess) {
          _fail(uploaded.error!, title: 'Upload failed');
          return null;
        }
        return slot.data!.path;
      } on VideoTooLarge catch (e) {
        final lower = video.quality.lower;
        if (lower == null) {
          final mb = (e.maxBytes / (1024 * 1024)).round();
          _fail(
            'This video is too large to upload (limit $mb MB). '
            'Try a shorter clip.',
            title: 'Video too large',
          );
          return null;
        }

        state = state.copyWith(step: ComposeStep.preparing, progress: 0.0);
        video = await _encode(
          video.sourcePath,
          duration: video.duration,
          quality: lower,
        );
        if (!ref.mounted) return null;
      }
    }
  }

  /// Polls the post until Instagram finishes (or we give up waiting).
  Future<Post?> _waitForResult(Post post) async {
    final deadline = DateTime.now().add(_pollTimeout);
    var current = post;

    while (!current.isFinished && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollInterval);
      if (!ref.mounted) return null;

      final response = await _repo.fetchPost(current.id);
      if (response.isSuccess) current = response.data!;
    }
    return current;
  }

  Future<PreparedVideo> _encode(
    String sourcePath, {
    required Duration duration,
    ReelQuality quality = ReelQuality.fullHd,
  }) async {
    _isEncoding = true;
    try {
      return await encodeReel(
        sourcePath,
        duration: duration,
        quality: quality,
        onProgress: _setProgress,
      );
    } finally {
      _isEncoding = false;
    }
  }

  void _setProgress(double value) {
    if (ref.mounted) state = state.copyWith(progress: value);
  }

  void _fail(String message, {String title = 'Publish failed'}) {
    state = state.copyWith(step: ComposeStep.idle, progress: null);
    _dialog.showError(message, title: title);
  }
}
