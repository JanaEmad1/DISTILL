import 'package:distill/core/constants.dart';
import 'package:distill/features/documents/data/share_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  group('buildShareText', () {
    test('includes the name, summary, and every key point', () {
      final doc = Fixtures.document(
        name: 'Q4 Report.pdf',
        summary: 'Revenue grew 12% year over year.',
        keyPoints: const ['Revenue up 12%', 'Costs flat', 'Margin improved'],
      );

      final text = buildShareText(doc);

      expect(text, contains('Q4 Report.pdf'));
      expect(text, contains('AI Summary'));
      expect(text, contains('Revenue grew 12% year over year.'));
      expect(text, contains('Key Points'));
      expect(text, contains('• Revenue up 12%'));
      expect(text, contains('• Costs flat'));
      expect(text, contains('• Margin improved'));
      expect(text, contains('Summarized with Distill'));
    });

    test('omits empty sections gracefully (in-progress document)', () {
      final doc = Fixtures.document(
        name: 'Pending.pdf',
        status: DocStatus.summarizing,
        summary: null,
        keyPoints: const [],
      );

      final text = buildShareText(doc);

      expect(text, contains('Pending.pdf'));
      expect(text, isNot(contains('AI Summary')));
      expect(text, isNot(contains('Key Points')));
      expect(text, contains('Summarized with Distill'));
    });
  });
}
