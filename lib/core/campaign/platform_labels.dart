const _platformLabels = <String, String>{
  'instagram_reel': 'Instagram Reel',
  'instagram_reels': 'Instagram Reel',
  'instagram_post': 'Instagram Post',
  'youtube_shorts': 'YouTube Shorts',
  'twitter_tweet': 'Twitter / X',
};

String formatPlatformLabel(String platformId) {
  return _platformLabels[platformId] ??
      platformId.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.substring(1)}';
      }).join(' ');
}

String formatPlatformList(List<String> platformIds) {
  if (platformIds.isEmpty) return 'Instagram Reel';
  return platformIds.map(formatPlatformLabel).join(' · ');
}
