/// Portal wizard stores composed `brief` as HOOK + DO + AVOID while also
/// persisting hook, doRules, and avoidRules separately.
String stripComposedBriefSections(String raw) {
  var remainder = raw.trim();
  if (remainder.isEmpty) return '';

  // Strip inline AVOID: block (with or without leading newlines)
  final avoidIdx = RegExp(r'(\n\n|\A)AVOID:\s*', caseSensitive: false)
      .firstMatch(remainder)
      ?.start;
  if (avoidIdx != null) {
    remainder = remainder.substring(0, avoidIdx).trim();
  }

  // Strip inline DO: block (with or without leading newlines)
  final doIdx = RegExp(r'(\n\n|\A)DO:\s*', caseSensitive: false)
      .firstMatch(remainder)
      ?.start;
  if (doIdx != null) {
    remainder = remainder.substring(0, doIdx).trim();
  }

  if (remainder.toUpperCase().startsWith('HOOK:')) {
    remainder = remainder.substring(5).trim();
  }

  return remainder;
}

bool hasStructuredCampaignBrief({
  String? briefHook,
  List<String> doRuleLines = const [],
  List<String> avoidRuleLines = const [],
}) {
  return (briefHook?.trim().isNotEmpty ?? false) ||
      doRuleLines.isNotEmpty ||
      avoidRuleLines.isNotEmpty;
}

/// Narrative brief only; excludes do/avoid blocks shown in their own sections.
String? resolveCampaignDisplayBrief({
  required String brief,
  String? briefHook,
  List<String> doRuleLines = const [],
  List<String> avoidRuleLines = const [],
}) {
  final hook = briefHook?.trim();
  if (hook != null && hook.isNotEmpty) {
    return hook;
  }

  if (hasStructuredCampaignBrief(
    briefHook: briefHook,
    doRuleLines: doRuleLines,
    avoidRuleLines: avoidRuleLines,
  )) {
    final stripped = stripComposedBriefSections(brief);
    return stripped.isEmpty ? null : stripped;
  }

  final trimmed = brief.trim();
  return trimmed.isEmpty ? null : trimmed;
}
