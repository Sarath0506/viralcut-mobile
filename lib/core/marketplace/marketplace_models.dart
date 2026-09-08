class MarketplaceListing {
  MarketplaceListing({
    required this.sourceDeliverableId,
    required this.platform,
    required this.mediaUrl,
    required this.viewCount,
    required this.likeCount,
    required this.creatorName,
    this.creatorAvatarUrl,
    required this.repostCount,
    this.maxRepostsPerClip,
  });

  final String sourceDeliverableId;
  final String platform;
  final String? mediaUrl;
  final int viewCount;
  final int likeCount;
  final String creatorName;
  final String? creatorAvatarUrl;
  final int repostCount;
  final int? maxRepostsPerClip;

  bool get isAtRepostCap =>
      maxRepostsPerClip != null && repostCount >= maxRepostsPerClip!;

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) =>
      MarketplaceListing(
        sourceDeliverableId: json['sourceDeliverableId'] as String,
        platform: json['platform'] as String,
        mediaUrl: json['mediaUrl'] as String?,
        viewCount: json['viewCount'] as int? ?? 0,
        likeCount: json['likeCount'] as int? ?? 0,
        creatorName: json['creatorName'] as String? ?? 'Creator',
        creatorAvatarUrl: json['creatorAvatarUrl'] as String?,
        repostCount: json['repostCount'] as int? ?? 0,
        maxRepostsPerClip: json['maxRepostsPerClip'] as int?,
      );
}

class MarketplaceRepostResult {
  MarketplaceRepostResult({
    required this.deliverableId,
    required this.status,
    this.livePostUrl,
  });

  final String deliverableId;
  final String status;
  final String? livePostUrl;

  factory MarketplaceRepostResult.fromJson(Map<String, dynamic> json) =>
      MarketplaceRepostResult(
        deliverableId: json['deliverableId'] as String,
        status: json['status'] as String,
        livePostUrl: json['livePostUrl'] as String?,
      );
}
