import 'package:Confygre_Email/components/GlobalVariables.dart';
import 'package:Confygre_Email/components/emails.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email safety', () {
    tearDown(() {
      permanentDelete = false;
    });

    test('unsubscribe parser extracts mailto and web targets', () {
      final parsed = parseUnsubscribeString(
        '<mailto:unsubscribe@example.com?subject=remove>, <https://example.com/unsubscribe>',
      );
      expect(parsed.mailToString, 'unsubscribe@example.com');
      expect(parsed.mailToSubject, 'remove');
      expect(parsed.directString, 'https://example.com/unsubscribe');
    });

    test('emptyTrash refuses to run without explicit confirmation', () async {
      await expectLater(
        emptyTrash(),
        throwsA(isA<StateError>()),
      );
    });

    test('permanent delete refuses to run without explicit confirmation', () async {
      permanentDelete = true;
      await expectLater(
        deleteSelectedMessages(['message-id']),
        throwsA(isA<StateError>()),
      );
    });
  });
}
