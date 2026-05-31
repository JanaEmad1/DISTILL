import 'package:distill/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ErrorView', () {
    testWidgets('renders the title and message', (tester) async {
      await tester.pumpApp(const ErrorView(message: 'No internet connection.'));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('No internet connection.'), findsOneWidget);
    });

    testWidgets('hides Retry when no callback is given', (tester) async {
      await tester.pumpApp(const ErrorView());

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows Retry and invokes the callback when tapped',
        (tester) async {
      var taps = 0;
      await tester.pumpApp(ErrorView(onRetry: () => taps++));

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
