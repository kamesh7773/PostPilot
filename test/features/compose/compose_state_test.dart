import 'package:postpilot/features/compose/view_models/compose_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('progress accepts int and double, and can be cleared', () {
    const state = ComposeState();

    expect(state.copyWith(progress: 0).progress, 0.0);
    expect(state.copyWith(progress: 0.5).progress, 0.5);
    expect(
      state.copyWith(progress: 0.5).copyWith(progress: null).progress,
      isNull,
    );
    expect(state.copyWith(progress: 0.5).copyWith().progress, 0.5);
  });

  test('can leave only when idle or waiting on Instagram', () {
    const state = ComposeState();

    expect(state.copyWith(step: ComposeStep.idle).canLeave, isTrue);
    expect(state.copyWith(step: ComposeStep.publishing).canLeave, isTrue);
    expect(state.copyWith(step: ComposeStep.preparing).canLeave, isFalse);
    expect(state.copyWith(step: ComposeStep.uploading).canLeave, isFalse);
  });

  test('carousel needs at least 2 items to publish', () {
    const state = ComposeState(kind: MediaKind.carousel, accountId: 'a');
    const one = [CarouselItem.photo('1.jpg')];
    const two = [CarouselItem.photo('1.jpg'), CarouselItem.photo('2.jpg')];

    expect(state.canPublish, isFalse);
    expect(state.copyWith(items: one).canPublish, isFalse);
    expect(state.copyWith(items: two).canPublish, isTrue);
  });
}
