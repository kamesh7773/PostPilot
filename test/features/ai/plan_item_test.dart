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
}
