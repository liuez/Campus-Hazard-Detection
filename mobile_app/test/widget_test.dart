import 'package:flutter_test/flutter_test.dart';

import 'package:safe_campus_ai/main.dart';

void main() {
  testWidgets('SafeCampus AI renders the detection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeCampusApp());

    expect(find.text('SafeCampus AI'), findsOneWidget);
    expect(find.text('Campus hazard scan'), findsOneWidget);
    expect(find.text('Detect Hazard'), findsOneWidget);
  });
}
