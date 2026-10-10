import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasknest_flutter/pages/add_task_page.dart';

void main() {
  Widget buildApp() => const MaterialApp(home: AddTaskPage());

  testWidgets('shows a validation error when the title is empty', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Task title is required.'), findsOneWidget);
  });

  testWidgets('shows a validation error for a blank title', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Task title is required.'), findsOneWidget);
  });
}
