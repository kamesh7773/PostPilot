import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

/// Instagram Reels limits (IG User Media reference).
class ReelVideoSpec {
  ReelVideoSpec._();

  static const Duration minDuration = Duration(seconds: 3);
  static const Duration maxDuration = Duration(minutes: 15);
}

/// Encoding presets, best first. Each step down is used when the file is
/// too large for the storage limit.
enum ReelQuality {
  fullHd(VideoQuality.Res1920x1080Quality, '1080p'),
  hd(VideoQuality.Res1280x720Quality, '720p');

  final VideoQuality preset;
  final String label;

  const ReelQuality(this.preset, this.label);

  ReelQuality? get lower {
    final next = index + 1;
    return next < values.length ? values[next] : null;
  }
}

class ReelVideoException implements Exception {
  final String message;

  const ReelVideoException(this.message);

  @override
  String toString() => message;
}

@immutable
class PreparedVideo {
  /// The picked original, kept to re-encode at a lower quality if needed.
  final String sourcePath;
  final String path;
  final int sizeBytes;
  final Duration duration;
  final String? thumbnailPath;
  final ReelQuality quality;

  const PreparedVideo({
    required this.sourcePath,
    required this.path,
    required this.sizeBytes,
    required this.duration,
    required this.thumbnailPath,
    required this.quality,
  });
}

/// Checks the length of a picked video. Throws [ReelVideoException].
Future<Duration> readReelDuration(String sourcePath) async {
  final info = await VideoCompress.getMediaInfo(sourcePath);
  final duration = Duration(milliseconds: (info.duration ?? 0).round());

  if (duration < ReelVideoSpec.minDuration) {
    throw const ReelVideoException('Reels must be at least 3 seconds long.');
  }
  if (duration > ReelVideoSpec.maxDuration) {
    throw const ReelVideoException('Reels can be at most 15 minutes long.');
  }
  return duration;
}

/// Re-encodes a video into what Instagram expects: MP4, H.264/AAC, 30 fps,
/// with the index at the start of the file ("fast start").
///
/// [onProgress] receives 0.0–1.0.
Future<PreparedVideo> encodeReel(
  String sourcePath, {
  required Duration duration,
  ReelQuality quality = ReelQuality.fullHd,
  ValueChanged<double>? onProgress,
}) async {
  final subscription = VideoCompress.compressProgress$.subscribe(
    (percent) => onProgress?.call((percent / 100).clamp(0.0, 1.0)),
  );

  try {
    final result = await VideoCompress.compressVideo(
      sourcePath,
      quality: quality.preset,
      includeAudio: true,
      frameRate: 30,
    );
    final path = result?.path;
    if (result == null || path == null) {
      throw const ReelVideoException("This video couldn't be prepared.");
    }

    final thumbnail = await VideoCompress.getFileThumbnail(
      path,
      quality: 70,
    ).then((f) => f.path).catchError((Object _) => '');

    return PreparedVideo(
      sourcePath: sourcePath,
      path: path,
      sizeBytes: result.filesize ?? 0,
      duration: duration,
      thumbnailPath: thumbnail.isEmpty ? null : thumbnail,
      quality: quality,
    );
  } finally {
    subscription.unsubscribe();
  }
}

/// Stops an in-progress encode (e.g. when the user leaves the screen).
Future<void> cancelReelEncoding() => VideoCompress.cancelCompression();
