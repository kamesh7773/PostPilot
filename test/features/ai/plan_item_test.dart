import 'package:flutter_test/flutter_test.dart';
import 'package:postpilot/features/ai/models/plan_item.dart';

void main() {
  test('plan slot parses into a local time and filled state', () {
    final item = PlanItem.fromJson({
      'id': 'a',
      'format': 'reel',
      'date': '2026-10-12',
      'time': '19:30',
      'title': 'Stretch',
      'hook': 'Stiff?',
      'caption': 'Try this',
      'why': 'Evening scroll',
      'postId': null,
      'postStatus': null,
    });
    expect(item.when, DateTime(2026, 10, 12, 19, 30));
    expect(item.when.isUtc, isFalse);
    expect(item.isFilled, isFalse);
  });

  test('failed slots show a friendly error, never the raw provider one', () {
    PlanItem failed(String? error) => PlanItem.fromJson({
      'id': 'a',
      'format': 'image',
      'date': '2026-10-12',
      'time': '19:30',
      'title': 'T',
      'hook': '',
      'caption': '',
      'why': '',
      'autoError': error,
    });
    expect(failed(null).friendlyError, isNull);
    expect(
      failed('Connect Instagram, then try again.').friendlyError,
      'Connect Instagram, then try again.',
    );
    expect(
      failed(
        'You exceeded your current quota, please check your plan.',
      ).friendlyError,
      "We couldn't create this one. Please try again in a few minutes.",
    );
  });
}
