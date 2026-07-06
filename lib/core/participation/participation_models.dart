class ParticipationCreatorProfile {
  ParticipationCreatorProfile({
    required this.id,
    required this.platform,
    required this.handle,
    this.label,
    this.avatarUrl,
  });

  final String id;
  final String platform;
  final String handle;
  final String? label;
  final String? avatarUrl;

  factory ParticipationCreatorProfile.fromJson(Map<String, dynamic> json) =>
      ParticipationCreatorProfile(
        id: json['id'] as String,
        platform: json['platform'] as String,
        handle: json['handle'] as String,
        label: json['label'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  String get displayHandle => label ?? '@$handle';
}

class RejectionHistoryEvent {
  RejectionHistoryEvent({
    required this.id,
    required this.rejectionReason,
    required this.draftDriveUrl,
    required this.rejectedAt,
    this.reviewedByDisplayName,
  });

  final String id;
  final String rejectionReason;
  final String draftDriveUrl;
  final String rejectedAt;
  final String? reviewedByDisplayName;

  factory RejectionHistoryEvent.fromJson(Map<String, dynamic> json) =>
      RejectionHistoryEvent(
        id: json['id'] as String,
        rejectionReason: json['rejectionReason'] as String,
        draftDriveUrl: json['draftDriveUrl'] as String,
        rejectedAt: json['rejectedAt'] as String,
        reviewedByDisplayName: json['reviewedByDisplayName'] as String?,
      );
}

class FormatDeliverable {
  FormatDeliverable({
    required this.id,
    required this.platform,
    required this.status,
    this.draftDriveUrl,
    this.livePostUrl,
    this.rejectionReason,
    this.draftSubmittedAt,
    this.draftReviewedAt,
    this.liveSubmittedAt,
    this.rejectionHistory = const [],
    this.priorRejectionCount = 0,
    this.viewCount = 0,
    this.reach = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.estimatedPaise = 0,
    this.ratePer1kPaise = 0,
  });

  final String id;
  final String platform;
  final String status;
  final String? draftDriveUrl;
  final String? livePostUrl;
  final String? rejectionReason;
  final String? draftSubmittedAt;
  final String? draftReviewedAt;
  final String? liveSubmittedAt;
  final List<RejectionHistoryEvent> rejectionHistory;
  final int priorRejectionCount;
  final int viewCount;
  final int reach;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int estimatedPaise;
  final int ratePer1kPaise;

  factory FormatDeliverable.fromJson(Map<String, dynamic> json) =>
      FormatDeliverable(
        id: json['id'] as String,
        platform: json['platform'] as String,
        status: json['status'] as String,
        draftDriveUrl: json['draftDriveUrl'] as String?,
        livePostUrl: json['livePostUrl'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        draftSubmittedAt: json['draftSubmittedAt'] as String?,
        draftReviewedAt: json['draftReviewedAt'] as String?,
        liveSubmittedAt: json['liveSubmittedAt'] as String?,
        rejectionHistory: (json['rejectionHistory'] as List<dynamic>? ?? [])
            .map(
              (e) => RejectionHistoryEvent.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        priorRejectionCount: json['priorRejectionCount'] as int? ?? 0,
        viewCount:    json['viewCount']    as int? ?? 0,
        reach:        json['reach']        as int? ?? 0,
        likeCount:    json['likeCount']    as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        shareCount:   json['shareCount']   as int? ?? 0,
        estimatedPaise: json['estimatedPaise'] as int? ?? 0,
        ratePer1kPaise: json['ratePer1kPaise'] as int? ?? 0,
      );

  bool get isRejected => status == 'draft_rejected';
  bool get isApproved => status == 'draft_approved';
  bool get isLiveSubmitted => status == 'live_submitted';
  bool get isUnderReview => status == 'under_review';
  bool get isDraftPending => status == 'draft_pending';
  bool get isProofUnderReview => status == 'proof_under_review';
  bool get isProofApproved => status == 'proof_approved';
  bool get isProofRejected => status == 'proof_rejected';
  bool get hasSubmittedProof =>
      isLiveSubmitted || isProofUnderReview || isProofApproved || isProofRejected;

  String? get latestRejectionReason =>
      rejectionReason ??
      (rejectionHistory.isNotEmpty
          ? rejectionHistory.first.rejectionReason
          : null);

  String? get lastRejectedDriveUrl => rejectionHistory.isNotEmpty
      ? rejectionHistory.first.draftDriveUrl
      : null;
}

class ParticipationCampaign {
  ParticipationCampaign({
    required this.id,
    required this.title,
    required this.status,
    required this.platforms,
    this.brandCompanyName,
    this.brandLogoUrl,
    this.coverImageUrl,
    this.ratePer1kDisplay,
    this.ratePer1kPaise,
    this.maxPayoutPaise,
  });

  final String id;
  final String title;
  final String status;
  final List<String> platforms;
  final String? brandCompanyName;
  final String? brandLogoUrl;
  final String? coverImageUrl;
  final String? ratePer1kDisplay;
  final int? ratePer1kPaise;
  final int? maxPayoutPaise;

  factory ParticipationCampaign.fromJson(Map<String, dynamic> json) =>
      ParticipationCampaign(
        id: json['id'] as String,
        title: json['title'] as String,
        status: json['status'] as String,
        platforms: (json['platforms'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        brandCompanyName: json['brandCompanyName'] as String?,
        brandLogoUrl: json['brandLogoUrl'] as String?,
        coverImageUrl: json['coverImageUrl'] as String?,
        ratePer1kDisplay: json['ratePer1kDisplay'] as String?,
        ratePer1kPaise: json['ratePer1kPaise'] as int?,
        maxPayoutPaise: json['maxPayoutPaise'] as int?,
      );

  String get displayBrand => brandCompanyName ?? title;
}

class Participation {
  Participation({
    required this.id,
    required this.campaignId,
    required this.joinedAt,
    required this.platformsSnapshot,
    required this.summary,
    required this.campaign,
    required this.deliverables,
    this.creatorProfile,
  });

  final String id;
  final String campaignId;
  final String joinedAt;
  final List<String> platformsSnapshot;
  final String summary;
  final ParticipationCampaign campaign;
  final List<FormatDeliverable> deliverables;
  final ParticipationCreatorProfile? creatorProfile;

  factory Participation.fromJson(Map<String, dynamic> json) => Participation(
        id: json['id'] as String,
        campaignId: json['campaignId'] as String,
        joinedAt: json['joinedAt'] as String,
        platformsSnapshot: (json['platformsSnapshot'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        summary: json['summary'] as String,
        campaign: ParticipationCampaign.fromJson(
          json['campaign'] as Map<String, dynamic>,
        ),
        deliverables: (json['deliverables'] as List<dynamic>? ?? [])
            .map((e) => FormatDeliverable.fromJson(e as Map<String, dynamic>))
            .toList(),
        creatorProfile: json['creatorProfile'] != null
            ? ParticipationCreatorProfile.fromJson(
                json['creatorProfile'] as Map<String, dynamic>)
            : null,
      );

  bool get needsAction =>
      summary == 'action_required' || summary == 'drafts_incomplete';

  bool get isJoinedOnly => summary == 'joined';
}

class ParticipationListItem {
  ParticipationListItem({
    required this.id,
    required this.summary,
    required this.campaignId,
    required this.campaignTitle,
    required this.platforms,
    required this.joinedAt,
    required this.deliverables,
    this.brandCompanyName,
    this.brandLogoUrl,
    this.coverImageUrl,
    this.creatorProfile,
  });

  final String id;
  final String summary;
  final String campaignId;
  final String campaignTitle;
  final String? brandCompanyName;
  final String? brandLogoUrl;
  final String? coverImageUrl;
  final List<String> platforms;
  final String joinedAt;
  final List<FormatDeliverable> deliverables;
  final ParticipationCreatorProfile? creatorProfile;

  factory ParticipationListItem.fromJson(Map<String, dynamic> json) =>
      ParticipationListItem(
        id: json['id'] as String,
        summary: json['summary'] as String,
        campaignId: json['campaignId'] as String,
        campaignTitle: json['campaignTitle'] as String,
        brandCompanyName: json['brandCompanyName'] as String?,
        brandLogoUrl: json['brandLogoUrl'] as String?,
        coverImageUrl: json['coverImageUrl'] as String?,
        platforms: (json['platforms'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        joinedAt: json['joinedAt'] as String,
        deliverables: (json['deliverables'] as List<dynamic>? ?? [])
            .map((e) => FormatDeliverable.fromJson(e as Map<String, dynamic>))
            .toList(),
        creatorProfile: json['creatorProfile'] != null
            ? ParticipationCreatorProfile.fromJson(
                json['creatorProfile'] as Map<String, dynamic>)
            : null,
      );

  String get displayBrand => brandCompanyName ?? campaignTitle;
}
