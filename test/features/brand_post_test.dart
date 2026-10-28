import 'package:flutter_test/flutter_test.dart';
import 'package:postpilot/features/brands/models/brand_post.dart';

BrandPost post(String status, {Object? instagram, Object? facebook}) =>
    BrandPost.fromJson({
      'id': 'p1',
      'format': 'image',
      'idea': '',
      'changeRequests': <String>[],
      'caption': 'Hi',
      'mediaUrls': ['https://x/a.jpg'],
      'status': status,
      'error': null,
      'instagram': instagram,
      'facebook': facebook,
      'createdAt': '2026-10-27T10:00:00Z',
    });

Map<String, Object?> state(String status) => {'status': status};

void main() {
  test('an approved post is publishing until both platforms finish', () {
    expect(
      post('approved').isPublishing,
      isTrue,
      reason: 'nothing reported yet',
    );
    expect(
      post(
        'approved',
        instagram: state('published'),
        facebook: state('publishing'),
      ).isPublishing,
      isTrue,
    );
    final done = post(
      'approved',
      instagram: state('published'),
      facebook: state('published'),
    );
    expect(done.isPublishing, isFalse);
    expect(done.publishFailed, isFalse);
  });

  test('approving again is offered once a platform gave up', () {
    final p = post(
      'approved',
      instagram: state('published'),
      facebook: state('failed'),
    );
    expect(p.publishFailed, isTrue);
    // Instagram retries on its own while scheduled: not failed yet.
    expect(
      post(
        'approved',
        instagram: state('scheduled'),
        facebook: state('failed'),
      ).publishFailed,
      isFalse,
    );
    expect(post('review').publishFailed, isFalse);
  });
}
