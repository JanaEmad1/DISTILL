import 'package:distill/features/chat/data/models/chat_message.dart';
import 'package:distill/features/chat/ui/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('MessageBubble', () {
    testWidgets('renders the message text', (tester) async {
      await tester.pumpApp(
        MessageBubble(message: Fixtures.message(text: 'Hello there')),
      );
      expect(find.text('Hello there'), findsOneWidget);
    });

    testWidgets('renders citation cards for AI replies', (tester) async {
      await tester.pumpApp(
        MessageBubble(
          message: Fixtures.message(
            isUser: false,
            text: 'See the source.',
            citations: const [Citation(quote: 'a key finding', page: 3)],
          ),
        ),
      );

      expect(find.text('"a key finding"'), findsOneWidget);
      expect(find.text('Page 3'), findsOneWidget);
    });

    testWidgets('shows typing dots (no text) while pending', (tester) async {
      await tester.pumpApp(
        MessageBubble(message: Fixtures.message(text: '', pending: true)),
      );

      // Three pulsing dots are rendered as CircleAvatars; no body text.
      expect(find.byType(CircleAvatar), findsNWidgets(3));
      expect(find.byType(Text), findsNothing);

      // Settle the repeating animation so the test can tear down cleanly.
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
