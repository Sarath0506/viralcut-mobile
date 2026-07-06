class LeaderboardEntry {
  LeaderboardEntry({
    required this.creatorId,
    required this.displayName,
    required this.avatarUrl,
    required this.totalViews,
    required this.totalEarnedPaise,
    required this.rank,
    this.creatorProfileId,
    this.handle,
    this.platform,
  });

  final String creatorId;
  final String displayName;
  final String? avatarUrl;
  final int totalViews;
  final int totalEarnedPaise;
  final int rank;
  /// Only present on per-campaign leaderboards, where each linked profile
  /// competes independently (the same creatorId can appear more than once).
  final String? creatorProfileId;
  final String? handle;
  final String? platform;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        creatorId: json['creatorId'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        totalViews: json['totalViews'] as int? ?? 0,
        totalEarnedPaise: json['totalEarnedPaise'] as int? ?? 0,
        rank: json['rank'] as int,
        creatorProfileId: json['creatorProfileId'] as String?,
        handle: json['handle'] as String?,
        platform: json['platform'] as String?,
      );

  /// Identity to match "is this row me" against — prefers the specific
  /// profile when available, falls back to the person for overall boards.
  String get identityKey => creatorProfileId ?? creatorId;
}

class Leaderboard {
  Leaderboard({
    required this.campaignId,
    required this.totalParticipants,
    required this.entries,
    this.currentUser,
  });

  final String campaignId;
  final int totalParticipants;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentUser;

  factory Leaderboard.fromJson(Map<String, dynamic> json) => Leaderboard(
        campaignId: json['campaignId'] as String,
        totalParticipants: json['totalParticipants'] as int? ?? 0,
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentUser: json['currentUser'] != null
            ? LeaderboardEntry.fromJson(json['currentUser'] as Map<String, dynamic>)
            : null,
      );
}

class OverallLeaderboard {
  OverallLeaderboard({
    required this.totalParticipants,
    required this.entries,
    this.currentUser,
  });

  final int totalParticipants;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentUser;

  factory OverallLeaderboard.fromJson(Map<String, dynamic> json) => OverallLeaderboard(
        totalParticipants: json['totalParticipants'] as int? ?? 0,
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentUser: json['currentUser'] != null
            ? LeaderboardEntry.fromJson(json['currentUser'] as Map<String, dynamic>)
            : null,
      );
}
