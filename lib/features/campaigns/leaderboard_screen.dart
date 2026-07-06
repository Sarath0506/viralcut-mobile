import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/format/money_format.dart';
import '../../core/widgets/vc_scaffold.dart';
import '../../theme/viralcut_colors.dart';
import 'campaign_providers.dart';

String _formatViews(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(2)}K';
  return '$n';
}

typedef _Board = ({
  int totalParticipants,
  List<LeaderboardEntry> entries,
  LeaderboardEntry? currentUser,
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key, this.campaignId});

  /// Null shows the overall leaderboard across all campaigns.
  final String? campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = campaignId;
    final AsyncValue<_Board> leaderboard = id != null
        ? ref.watch(campaignLeaderboardProvider(id)).whenData(
              (b) => (
                totalParticipants: b.totalParticipants,
                entries: b.entries,
                currentUser: b.currentUser,
              ),
            )
        : ref.watch(overallLeaderboardProvider).whenData(
              (b) => (
                totalParticipants: b.totalParticipants,
                entries: b.entries,
                currentUser: b.currentUser,
              ),
            );
    final vc = ViralCutColors.of(context);

    return VcScaffold(
      title: id != null ? 'Leaderboard' : 'Overall Leaderboard',
      showBack: true,
      body: leaderboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('$e', style: TextStyle(color: vc.muted)),
        ),
        data: (board) {
          if (board.entries.isEmpty) {
            return Center(
              child: Text(
                id != null ? 'No submissions yet' : 'No creators yet',
                style: GoogleFonts.inter(fontSize: 14, color: vc.muted),
              ),
            );
          }

          final showCurrentUserBar = board.currentUser != null &&
              !board.entries.any((e) => e.identityKey == board.currentUser!.identityKey);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${board.totalParticipants} participants',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: vc.muted,
                      ),
                    ),
                    Text(
                      'Ranked by views',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: vc.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: board.entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final entry = board.entries[i];
                    final isMe = entry.identityKey == board.currentUser?.identityKey;
                    return _LeaderboardRow(entry: entry, highlighted: isMe);
                  },
                ),
              ),
              if (showCurrentUserBar)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    10 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: vc.surface,
                    border: Border(top: BorderSide(color: vc.border)),
                  ),
                  child: _LeaderboardRow(
                    entry: board.currentUser!,
                    highlighted: true,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.highlighted});

  final LeaderboardEntry entry;
  final bool highlighted;

  Color _rankColor(ViralCutColors vc) {
    switch (entry.rank) {
      case 1:
        return const Color(0xFFFFC94D);
      case 2:
        return const Color(0xFFC7CCD1);
      case 3:
        return const Color(0xFFCE8946);
      default:
        return vc.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vc = ViralCutColors.of(context);
    final rankColor = _rankColor(vc);
    final letter = entry.displayName.isNotEmpty
        ? entry.displayName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlighted ? vc.primary.withValues(alpha: 0.08) : vc.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? vc.primary.withValues(alpha: 0.4) : vc.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: vc.primary.withValues(alpha: 0.12),
            backgroundImage:
                entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(
                    letter,
                    style: TextStyle(
                      color: vc.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlighted ? '${entry.displayName} (You)' : entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: vc.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 11, color: vc.muted),
                    const SizedBox(width: 3),
                    Text(
                      entry.handle != null
                          ? '@${entry.handle} · ${_formatViews(entry.totalViews)} views'
                          : '${_formatViews(entry.totalViews)} views',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: vc.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            formatPaise(entry.totalEarnedPaise),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: vc.money,
            ),
          ),
        ],
      ),
    );
  }
}
