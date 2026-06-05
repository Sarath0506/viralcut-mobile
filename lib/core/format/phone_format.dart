/// Normalizes India mobile input to E.164 `+91XXXXXXXXXX` for the API.
String? normalizeIndiaPhone({
  required String countryCode,
  required String localNumber,
}) {
  final codeDigits = countryCode.replaceAll(RegExp(r'\D'), '');
  final localDigits = localNumber.replaceAll(RegExp(r'\D'), '');
  if (localDigits.length != 10) return null;
  if (codeDigits != '91') return null;
  if (!RegExp(r'^[6-9]').hasMatch(localDigits)) return null;
  return '+91$localDigits';
}

String formatLocalPhoneDisplay(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  if (d.length <= 5) return d;
  if (d.length <= 10) {
    return '${d.substring(0, 5)} ${d.substring(5)}';
  }
  return d.substring(0, 10);
}
