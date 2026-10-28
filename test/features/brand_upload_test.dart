import 'package:flutter_test/flutter_test.dart';
import 'package:postpilot/features/brands/repositories/brands_repository.dart';

void main() {
  test('the format follows the files', () {
    expect(formatFor(['a.mp4'], 'image'), 'reel');
    expect(formatFor(['a.jpg', 'b.PNG'], 'image'), 'carousel');
    expect(formatFor(['a.jpg'], 'carousel'), 'image');
    expect(formatFor(['a.jpg'], 'story'), 'story', reason: 'a Story stays a Story');
    expect(formatFor([], 'story'), 'story');
  });

  test('file types', () {
    expect(mimeTypeOf('Photo.JPG'), 'image/jpeg');
    expect(mimeTypeOf('clip.mov'), 'video/quicktime');
    expect(isVideoFile('clip.MP4'), isTrue);
    expect(isVideoFile('a.webp'), isFalse);
  });
}
