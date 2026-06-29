import 'package:intl/intl.dart';

import 'campaign_models.dart';

/// Default live window when the API has no explicit end date.
const defaultCampaignRunDays = 14;

DateTime? parseCampaignDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw);
}

DateTime? resolveCampaignStart(Campaign campaign) =>
    parseCampaignDate(campaign.startDate) ?? parseCampaignDate(campaign.createdAt);

DateTime? resolveCampaignEndDate(Campaign campaign) {
  final start = resolveCampaignStart(campaign);
  if (start == null) return null;
  final dayStart = DateTime(start.year, start.month, start.day);
  return dayStart.add(const Duration(days: defaultCampaignRunDays));
}

String _countdownSuffix(DateTime target, DateTime now) {
  final diff = target.difference(now);
  if (diff.isNegative) return '';

  final days = diff.inDays;
  if (days >= 1) return '${days}d';
  final hours = diff.inHours;
  if (hours >= 1) return '${hours}h';
  return 'soon';
}

String _prefixCountdown({
  required DateTime target,
  required DateTime now,
  required String prefix,
  required String soonLabel,
}) {
  final suffix = _countdownSuffix(target, now);
  if (suffix.isEmpty) return soonLabel;
  if (suffix == 'soon') return soonLabel;
  return '$prefix $suffix';
}

/// Human-readable timing label for list/carousel cards.
String campaignScheduleLabel(Campaign campaign) {
  final now = DateTime.now();
  final start = resolveCampaignStart(campaign);

  if (start != null && start.isAfter(now)) {
    return _prefixCountdown(
      target: start,
      now: now,
      prefix: 'Starts in',
      soonLabel: 'Starts soon',
    );
  }

  final end = resolveCampaignEndDate(campaign);
  if (end != null && end.isAfter(now)) {
    return _prefixCountdown(
      target: end,
      now: now,
      prefix: 'Ends in',
      soonLabel: 'Ends soon',
    );
  }

  return 'Ends soon';
}

/// Right-side timing label for trending cards.
String campaignEndingLabel(Campaign campaign) => campaignScheduleLabel(campaign);

final _detailDate = DateFormat('d MMM');

/// Detail screen: start date only (no end date on campaigns).
String? campaignStartDetailLabel(Campaign campaign) {
  final start = resolveCampaignStart(campaign);
  if (start == null) return null;
  final label = _detailDate.format(start.toLocal());
  if (start.isAfter(DateTime.now())) return 'Starts $label';
  return 'Live since $label';
}

String? campaignDetailSubtitle(Campaign campaign) {
  final parts = <String>[];
  final brand = campaign.brandCompanyName?.trim();
  final title = campaign.title.trim();
  if (brand != null &&
      brand.isNotEmpty &&
      brand.toLowerCase() != title.toLowerCase()) {
    parts.add(brand);
  }
  parts.add(campaign.platformLabel);
  final category = campaign.category?.trim();
  if (category != null && category.isNotEmpty) {
    parts.add(category);
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

String dashboardGreetingName(String? displayName) {
  final trimmed = displayName?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'there';
  final first = trimmed.split(RegExp(r'\s+')).first;
  return first.isEmpty ? 'there' : first;
}
