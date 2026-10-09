import 'dart:io';

import 'package:base_flutter_application/features/compose/services/instagram_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('ig_image_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  ({int width, int height, bool cropped}) fit(
    int width,
    int height, {
    bool feed = true,
  }) {
    final input = '${dir.path}/in_${width}x$height.jpg';
    final output = '${dir.path}/out_${width}x$height.jpg';
    File(
      input,
    ).writeAsBytesSync(img.encodeJpg(img.Image(width: width, height: height)));

    final result = fitToInstagram((input, output, feed))!;
    final out = img.decodeJpg(File(result.path).readAsBytesSync())!;
    return (width: out.width, height: out.height, cropped: result.wasCropped);
  }

  void expectWithinInstagramLimits(({int width, int height, bool cropped}) r) {
    final ratio = r.width / r.height;
    expect(
      ratio,
      greaterThanOrEqualTo(InstagramImageSpec.minAspectRatio - 0.01),
    );
    expect(ratio, lessThanOrEqualTo(InstagramImageSpec.maxAspectRatio + 0.01));
    expect(r.width, lessThanOrEqualTo(InstagramImageSpec.maxWidth));
  }

  test('9:16 phone photo is cropped to 4:5', () {
    final r = fit(1080, 1920);
    expect(r.cropped, isTrue);
    expect(r.width, 1080);
    expect(r.height, 1350);
    expectWithinInstagramLimits(r);
  });

  test('3:1 panorama is cropped to 1.91:1', () {
    final r = fit(1440, 480);
    expect(r.cropped, isTrue);
    expect(r.height, 480);
    expectWithinInstagramLimits(r);
  });

  test('story keeps its 9:16 shape', () {
    final r = fit(1080, 1920, feed: false);
    expect(r.cropped, isFalse);
    expect((r.width, r.height), (1080, 1920));
  });

  test('square photo is left as is', () {
    final r = fit(1080, 1080);
    expect(r.cropped, isFalse);
    expect((r.width, r.height), (1080, 1080));
  });

  test('4:5 portrait at the limit is not cropped', () {
    final r = fit(1080, 1350);
    expect(r.cropped, isFalse);
    expectWithinInstagramLimits(r);
  });

  test('wide image is scaled down to 1440px', () {
    final r = fit(2000, 1500);
    expect(r.cropped, isFalse);
    expect(r.width, 1440);
    expectWithinInstagramLimits(r);
  });
}
