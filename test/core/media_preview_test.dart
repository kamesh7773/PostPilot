import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postpilot/core/widgets/media_preview.dart';

void main() {
  testWidgets('carousel slides page with the arrows and open full screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaPreview(
            format: 'carousel',
            urls: ['a.jpg', 'b.jpg', 'c.jpg'],
            emptyText: '',
          ),
        ),
      ),
    );
    expect(find.text('1/3'), findsOneWidget);
    expect(find.byTooltip('Previous'), findsNothing);

    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    expect(find.byTooltip('Previous'), findsOneWidget);

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(
      find.text('2/3'),
      findsNWidgets(2),
      reason: 'full screen opens on the same slide',
    );
  });
}
