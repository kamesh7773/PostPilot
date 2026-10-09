import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

/// Instagram feed image limits (IG User Media reference).
class InstagramImageSpec {
  InstagramImageSpec._();

  /// Tallest allowed: 4:5 portrait.
  static const double minAspectRatio = 4 / 5;

  /// Widest allowed: 1.91:1 landscape.
  static const double maxAspectRatio = 1.91;

  static const int maxWidth = 1440;
  static const int jpegQuality = 90;
}

@immutable
class PreparedImage {
  final String path;

  /// True when the photo was center-cropped to fit Instagram's ratio range.
  final bool wasCropped;

  const PreparedImage({required this.path, required this.wasCropped});
}

/// Turns any picked photo (HEIC, PNG, JPEG, any shape) into a JPEG that
/// Instagram accepts: re-encoded, at most 1440px wide, and center-cropped
/// to the 4:5 – 1.91:1 aspect-ratio range when needed.
/// `feed: false` (Stories) keeps the original shape — Stories are full-screen.
Future<PreparedImage?> prepareInstagramImage(
  String sourcePath, {
  bool feed = true,
}) async {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final tmp = Directory.systemTemp.path;

  // Native decode (handles HEIC) + resize + JPEG encode. Scales so the short
  // side is at most 1440px; the crop below brings width within 1440.
  final jpeg = await FlutterImageCompress.compressAndGetFile(
    sourcePath,
    '$tmp/postpilot_${stamp}_src.jpg',
    minWidth: InstagramImageSpec.maxWidth,
    minHeight: InstagramImageSpec.maxWidth,
    quality: InstagramImageSpec.jpegQuality,
    format: CompressFormat.jpeg,
  );
  if (jpeg == null) return null;

  return compute(fitToInstagram, (
    jpeg.path,
    '$tmp/postpilot_$stamp.jpg',
    feed,
  ));
}

/// Crops/resizes a JPEG at `paths.$1` into `paths.$2`. Runs in a background
/// isolate because decoding and cropping are CPU-heavy.
@visibleForTesting
PreparedImage? fitToInstagram((String, String, bool) args) {
  final (inputPath, outputPath, feed) = args;
  final decoded = img.decodeJpg(File(inputPath).readAsBytesSync());
  if (decoded == null) return null;

  var image = decoded;
  var cropped = false;
  final ratio = image.width / image.height;

  if (feed && ratio < InstagramImageSpec.minAspectRatio) {
    // Too tall (e.g. 9:16): keep full width, trim top and bottom.
    final height = (image.width / InstagramImageSpec.minAspectRatio).floor();
    image = img.copyCrop(
      image,
      x: 0,
      y: (image.height - height) ~/ 2,
      width: image.width,
      height: height,
    );
    cropped = true;
  } else if (feed && ratio > InstagramImageSpec.maxAspectRatio) {
    // Too wide (e.g. panorama): keep full height, trim the sides.
    final width = (image.height * InstagramImageSpec.maxAspectRatio).floor();
    image = img.copyCrop(
      image,
      x: (image.width - width) ~/ 2,
      y: 0,
      width: width,
      height: image.height,
    );
    cropped = true;
  }

  if (image.width > InstagramImageSpec.maxWidth) {
    image = img.copyResize(image, width: InstagramImageSpec.maxWidth);
  }

  if (!cropped && identical(image, decoded)) {
    File(inputPath).renameSync(outputPath);
  } else {
    File(outputPath).writeAsBytesSync(
      img.encodeJpg(image, quality: InstagramImageSpec.jpegQuality),
    );
    File(inputPath).deleteSync();
  }
  return PreparedImage(path: outputPath, wasCropped: cropped);
}
