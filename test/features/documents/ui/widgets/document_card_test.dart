import 'package:distill/core/constants.dart';
import 'package:distill/features/documents/ui/widgets/document_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('DocumentCard', () {
    testWidgets('renders the document name and summary snippet',
        (tester) async {
      await tester.pumpApp(DocumentCard(
        doc: Fixtures.document(name: 'Report.pdf', summary: 'A short summary.'),
        onTap: () {},
      ));

      expect(find.text('Report.pdf'), findsOneWidget);
      expect(find.text('A short summary.'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('shows the "Summarized" badge when ready', (tester) async {
      await tester.pumpApp(DocumentCard(
        doc: Fixtures.document(status: DocStatus.ready),
        onTap: () {},
      ));
      expect(find.text('Summarized'), findsOneWidget);
    });

    testWidgets('shows a processing indicator while summarizing',
        (tester) async {
      await tester.pumpApp(DocumentCard(
        doc: Fixtures.document(status: DocStatus.summarizing, summary: null),
        onTap: () {},
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing AI insights…'), findsOneWidget);
    });

    testWidgets('shows an error line when processing failed', (tester) async {
      await tester.pumpApp(DocumentCard(
        doc: Fixtures.document(status: DocStatus.error, summary: null),
        onTap: () {},
      ));
      expect(find.text('Failed to process'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpApp(DocumentCard(
        doc: Fixtures.document(),
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(DocumentCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders a more button only when onMore is provided',
        (tester) async {
      var moreTaps = 0;
      await tester.pumpApp(DocumentCard(
        doc: Fixtures.document(),
        onTap: () {},
        onMore: () => moreTaps++,
      ));

      final moreButton = find.byType(IconButton);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      expect(moreTaps, 1);
    });
  });
}
