// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sagemovies/main.dart';
import 'package:sagemovies/app_state.dart';

void main() {
  testWidgets('App renders bottom navigation', (tester) async {
    await tester.pumpWidget(AppStateProvider(child: const SageMoviesApp()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('My List'), findsOneWidget);
  });
}
