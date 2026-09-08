import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/marketplace/marketplace_models.dart';
import '../../../theme/halchal_colors.dart';

const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'};

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

bool _looksLikeImage(String url) {
  final path = Uri.tryParse(url)?.path ?? url;
  final ext = path.split('.').last.toLowerCase();
  return _imageExtensions.contains(ext);
}

/// A compact, silently-autoplaying video preview for a marketplace listing.
/// Tapping the tile opens a bigger preview overlay on the same page; the
/// small repost badge in the corner is the dedicated one-tap repost action,
/// kept separate so browsing a clip and committing to it are distinct.
class MarketplaceVideoTile extends StatefulWidget {
  const MarketplaceVideoTile({
    super.key,
    required this.listing,
    required this.busy,
    required this.onRepost,
    required this.vc,
  });

  final MarketplaceListing listing;
  final bool busy;
  final VoidCallback onRepost;
  final HalchalColors vc;

  @override
  State<MarketplaceVideoTile> createState() => _MarketplaceVideoTileState();
}

class _MarketplaceVideoTileState extends State<MarketplaceVideoTile> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _isImage = false;

  @override
  void initState() {
    super.initState();
    final url = widget.listing.mediaUrl;
    if (url == null) {
      _failed = true;
      return;
    }
    if (_looksLikeImage(url)) {
      _isImage = true;
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      controller
        ..setVolume(0)
        ..setLooping(true)
        ..play();
      setState(() {});
    }).catchError((Object e, StackTrace st) {
      debugPrint('[MarketplaceVideoTile] failed to init $url: $e\n$st');
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openPreview() {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Clip preview',
      barrierDismissible: true,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => _MarketplaceVideoPreviewOverlay(
        listing: widget.listing,
        controller: _controller,
        isImage: _isImage,
        failed: _failed,
        busy: widget.busy,
        onRepost: widget.onRepost,
        vc: widget.vc,
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vc = widget.vc;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: vc.surface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: _openPreview,
                child: _MarketplaceMedia(
                  isImage: _isImage,
                  ready: ready,
                  failed: _failed,
                  controller: controller,
                  mediaUrl: widget.listing.mediaUrl,
                  vc: vc,
                ),
              ),

              // Bottom scrim + view count
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _formatCount(widget.listing.viewCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Repost affordance badge — the actual repost action.
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: widget.busy ? null : widget.onRepost,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.repeat_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              if (widget.busy)
                IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceMedia extends StatelessWidget {
  const _MarketplaceMedia({
    required this.isImage,
    required this.ready,
    required this.failed,
    required this.controller,
    required this.mediaUrl,
    required this.vc,
  });

  final bool isImage;
  final bool ready;
  final bool failed;
  final VideoPlayerController? controller;
  final String? mediaUrl;
  final HalchalColors vc;

  @override
  Widget build(BuildContext context) {
    if (isImage) {
      return CachedNetworkImage(
        imageUrl: mediaUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Icon(
          Icons.image_not_supported_outlined,
          color: vc.muted,
          size: 26,
        ),
      );
    }
    if (ready) {
      final c = controller!;
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      );
    }
    if (failed) {
      return Center(
        child: Icon(Icons.videocam_off_rounded, color: vc.muted, size: 26),
      );
    }
    return Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: vc.primary),
      ),
    );
  }
}

class _MarketplaceVideoPreviewOverlay extends StatelessWidget {
  const _MarketplaceVideoPreviewOverlay({
    required this.listing,
    required this.controller,
    required this.isImage,
    required this.failed,
    required this.busy,
    required this.onRepost,
    required this.vc,
  });

  final MarketplaceListing listing;
  final VideoPlayerController? controller;
  final bool isImage;
  final bool failed;
  final bool busy;
  final VoidCallback onRepost;
  final HalchalColors vc;

  void _close(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media fills the screen behind everything else.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _close(context),
              child: _MarketplaceMedia(
                isImage: isImage,
                ready: ready,
                failed: failed,
                controller: controller,
                mediaUrl: listing.mediaUrl,
                vc: vc,
              ),
            ),
          ),

          // Close button — pinned to the top, never depends on content height.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _close(context),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.close_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats + Repost — pinned to the bottom, overlaying the media.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0), Colors.black87],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility_outlined, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatCount(listing.viewCount)} views',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.favorite_border_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatCount(listing.likeCount)} likes',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () {
                                _close(context);
                                onRepost();
                              },
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.repeat_rounded, size: 16),
                        label: const Text('Repost'),
                        style: FilledButton.styleFrom(
                          backgroundColor: vc.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
