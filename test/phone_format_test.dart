import 'package:flutter_test/flutter_test.dart';
import 'package:viralcut_mobile/core/format/phone_format.dart';

void main() {
  group('normalizeIndiaPhone', () {
    test('returns E.164 for valid +91 number', () {
      expect(
        normalizeIndiaPhone(countryCode: '+91', localNumber: '9876543210'),
        '+919876543210',
      );
    });

    test('returns null for invalid first digit', () {
      expect(
        normalizeIndiaPhone(countryCode: '+91', localNumber: '5123456789'),
        isNull,
      );
    });

    test('returns null for wrong country code', () {
      expect(
        normalizeIndiaPhone(countryCode: '+1', localNumber: '9876543210'),
        isNull,
      );
    });

    test('returns null when local number is not 10 digits', () {
      expect(
        normalizeIndiaPhone(countryCode: '+91', localNumber: '987654321'),
        isNull,
      );
    });
  });

  group('isValidIndiaE164', () {
    test('accepts valid API phone', () {
      expect(isValidIndiaE164('+919876543210'), isTrue);
    });

    test('rejects invalid prefix', () {
      expect(isValidIndiaE164('+915123456789'), isFalse);
    });

    test('rejects null and empty', () {
      expect(isValidIndiaE164(null), isFalse);
      expect(isValidIndiaE164(''), isFalse);
    });
  });
}
