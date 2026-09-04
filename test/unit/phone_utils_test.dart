import 'package:flutter_test/flutter_test.dart';
import 'package:esquadrao_comercial/core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils Tests', () {
    test('cleanDigits removes all non-numeric characters', () {
      expect(PhoneUtils.cleanDigits('(61) 99999-8888'), equals('61999998888'));
      expect(PhoneUtils.cleanDigits('+55 61 98888.7777'), equals('5561988887777'));
      expect(PhoneUtils.cleanDigits('abc-123-xyz'), equals('123'));
    });

    test('toTelUri formats correctly for native dialer launch', () {
      expect(PhoneUtils.toTelUri('61999998888'), equals('tel:+5561999998888'));
      expect(PhoneUtils.toTelUri('061999998888'), equals('tel:+5561999998888'));
      expect(PhoneUtils.toTelUri('5561999998888'), equals('tel:+5561999998888'));
      expect(PhoneUtils.toTelUri('(11) 97777-6666'), equals('tel:+5511977776666'));
    });

    test('formatDisplay formats phone numbers with standard DDD mask', () {
      expect(PhoneUtils.formatDisplay('61999998888'), equals('(61) 99999-8888'));
      expect(PhoneUtils.formatDisplay('6133334444'), equals('(61) 3333-4444'));
      expect(PhoneUtils.formatDisplay('5561999998888'), equals('(61) 99999-8888'));
    });

    test('isValidBrazilianPhone validates proper lengths', () {
      expect(PhoneUtils.isValidBrazilianPhone('61999998888'), isTrue); // 11 dígitos
      expect(PhoneUtils.isValidBrazilianPhone('(61) 3333-4444'), isTrue); // 10 dígitos
      expect(PhoneUtils.isValidBrazilianPhone('123'), isFalse); // Muito curto
      expect(PhoneUtils.isValidBrazilianPhone(''), isFalse);
    });
  });
}
