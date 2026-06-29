import 'campaign_brief_display.dart';
import 'platform_labels.dart';

class CampaignAsset {
  const CampaignAsset({
    required this.type,
    required this.url,
    this.label,
  });

  final String type;
  final String url;
  final String? label;

  factory CampaignAsset.fromJson(Map<String, dynamic> json) => CampaignAsset(
        type: json['type'] as String? ?? '',
        url: json['url'] as String? ?? '',
        label: json['label'] as String?,
      );
}

List<CampaignAsset> _parseAssets(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(CampaignAsset.fromJson)
      .where((a) => a.url.isNotEmpty)
      .toList();
}

List<String> parseRuleLines(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(RegExp(r'\r?\n'))
      .map((line) => line.replaceFirst(RegExp(r'^[\s\u2022\u2013\-*]+'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

class Campaign {
  Campaign({
    required this.id,
    required this.title,
    required this.ratePer1kDisplay,
    required this.ratePer1kPaise,
    required this.maxPayoutPaise,
    required this.poolPercent,
    required this.poolRemainingPercent,
    required this.budgetPaise,
    required this.budgetUsedPaise,
    required this.brief,
    required this.platform,
    required this.platforms,
    required this.status,
    required this.sourceAssets,
    required this.referenceAssets,
    this.category,
    this.productUrl,
    this.briefHook,
    this.doRules,
    this.avoidRules,
    this.coverImageUrl,
    this.brandCompanyName,
    this.brandLogoUrl,
    this.startDate,
    this.createdAt,
  });

  final String id;
  final String title;
  final String ratePer1kDisplay;
  final int ratePer1kPaise;
  final int maxPayoutPaise;
  final int poolPercent;
  final int poolRemainingPercent;
  final int budgetPaise;
  final int budgetUsedPaise;
  final String brief;
  final String platform;
  final List<String> platforms;
  final String status;
  final List<CampaignAsset> sourceAssets;
  final List<CampaignAsset> referenceAssets;
  final String? category;
  final String? productUrl;
  final String? briefHook;
  final String? doRules;
  final String? avoidRules;
  final String? coverImageUrl;
  final String? brandCompanyName;
  final String? brandLogoUrl;
  final String? startDate;
  final String? createdAt;

  String get displayBrand => brandCompanyName?.trim().isNotEmpty == true
      ? brandCompanyName!.trim()
      : title;

  String get platformLabel =>
      formatPlatformList(platforms.isNotEmpty ? platforms : [platform]);

  List<String> get doRuleLines => parseRuleLines(doRules);

  List<String> get avoidRuleLines => parseRuleLines(avoidRules);

  int get poolRemainingPaise =>
      (budgetPaise - budgetUsedPaise).clamp(0, budgetPaise);

  bool get isPoolAlmostFull => poolPercent >= 70;

  String? get displayBrief => resolveCampaignDisplayBrief(
        brief: brief,
        briefHook: briefHook,
        doRuleLines: doRuleLines,
        avoidRuleLines: avoidRuleLines,
      );

  String? get briefExcerpt {
    final text = displayBrief;
    if (text == null || text.isEmpty) return null;
    if (text.length <= 120) return text;
    return '...';
  }

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'] as String,
        title: json['title'] as String,
        ratePer1kDisplay: json['ratePer1kDisplay'] as String,
        ratePer1kPaise: json['ratePer1kPaise'] as int? ?? 0,
        maxPayoutPaise: json['maxPayoutPaise'] as int,
        poolPercent: json['poolPercent'] as int? ?? 0,
        poolRemainingPercent: json['poolRemainingPercent'] as int? ??
            (100 - (json['poolPercent'] as int? ?? 0)),
        budgetPaise: json['budgetPaise'] as int? ?? 0,
        budgetUsedPaise: json['budgetUsedPaise'] as int? ?? 0,
        brief: json['brief'] as String? ?? '',
        platform: json['platform'] as String? ?? 'instagram_reel',
        platforms: (json['platforms'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        status: json['status'] as String? ?? 'live',
        sourceAssets: _parseAssets(json['sourceAssets']),
        referenceAssets: _parseAssets(json['referenceAssets']),
        category: json['category'] as String?,
        productUrl: json['productUrl'] as String?,
        briefHook: json['briefHook'] as String?,
        doRules: json['doRules'] as String?,
        avoidRules: json['avoidRules'] as String?,
        coverImageUrl: json['coverImageUrl'] as String?,
        brandCompanyName: json['brandCompanyName'] as String?,
        brandLogoUrl: json['brandLogoUrl'] as String?,
        startDate: json['startDate'] as String?,
        createdAt: json['createdAt'] as String?,
      );
}
