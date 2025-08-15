import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/src/i18n/messages.dart';

void main() {
  test('messages contain keys', () {
    expect(Messages.en['required'], isNotNull);
    expect(Messages.ptBR['required'], isNotNull);
  });
}
