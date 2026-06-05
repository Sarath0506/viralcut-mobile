import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:viralcut_mobile/app.dart';

void main() {
  testWidgets('app shell loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ViralCutApp()),
    );
    expect(find.byType(ViralCutApp), findsOneWidget);
  });
}
