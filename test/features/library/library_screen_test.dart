import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pod_mate/features/library/library_screen.dart';

void main() {
  testWidgets('shows the empty state when there are no podcasts', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('No podcasts yet'), findsOneWidget);
  });
}
