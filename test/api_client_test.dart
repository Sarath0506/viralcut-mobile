import 'package:flutter_test/flutter_test.dart';
import 'package:viralcut_mobile/core/api/api_client.dart';

void main() {
  group('ApiClient.parseErrorEnvelope', () {
    test('parses API failure envelope', () {
      final error = ApiClient.parseErrorEnvelope({
        'success': false,
        'data': null,
        'error': {
          'code': 'RATE_LIMITED',
          'message': 'Too many OTP requests. Try again in a minute.',
        },
      });

      expect(error, isNotNull);
      expect(error!.code, 'RATE_LIMITED');
      expect(error.message, contains('Too many OTP'));
    });

    test('returns null for success envelope', () {
      expect(
        ApiClient.parseErrorEnvelope({
          'success': true,
          'data': {'ok': true},
          'error': null,
        }),
        isNull,
      );
    });

    test('returns null for non-map body', () {
      expect(ApiClient.parseErrorEnvelope('not-json'), isNull);
    });
  });
}
