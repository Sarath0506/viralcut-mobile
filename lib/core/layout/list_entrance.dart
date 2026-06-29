import 'package:flutter/material.dart';

const Duration kListEntranceDuration = Duration(milliseconds: 1200);

/// Fade + slide-up entrance for vertically stacked cards/sections.
class ListStaggerEntrance extends StatelessWidget {
  const ListStaggerEntrance({
    super.key,
    required this.index,
    required this.animation,
    required this.child,
  });

  final int index;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = index * 0.1;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start.clamp(0.0, 0.85),
        (start + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 18),
            child: Transform.scale(
              scale: 0.97 + (curved.value * 0.03),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Drives [ListStaggerEntrance] for scrollable lists (campaigns, submissions).
mixin ListEntranceAnimationMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController listEntranceController = AnimationController(
    vsync: this,
    duration: kListEntranceDuration,
  );

  String? _listEntranceKey;

  void disposeListEntrance() {
    listEntranceController.dispose();
  }

  void invalidateListEntrance() {
    _listEntranceKey = null;
  }

  void playListEntrance(String listKey) {
    if (listKey == _listEntranceKey) return;
    _listEntranceKey = listKey;

    listEntranceController.reset();
    if (MediaQuery.disableAnimationsOf(context)) {
      listEntranceController.value = 1;
      return;
    }
    listEntranceController.forward();
  }
}

/// Staggered column for dashboard, wallet, profile, and other section screens.
class ScreenStaggeredColumn extends StatefulWidget {
  const ScreenStaggeredColumn({
    super.key,
    required this.animationKey,
    required this.children,
    this.padding,
    this.physics,
  });

  final String animationKey;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  State<ScreenStaggeredColumn> createState() => _ScreenStaggeredColumnState();
}

class _ScreenStaggeredColumnState extends State<ScreenStaggeredColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _playedKey;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kListEntranceDuration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playEntrance(widget.animationKey);
    });
  }

  @override
  void didUpdateWidget(covariant ScreenStaggeredColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationKey != widget.animationKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playEntrance(widget.animationKey);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playEntrance(String key) {
    if (key == _playedKey) return;
    _playedKey = key;

    _controller.reset();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: widget.physics,
      padding: widget.padding,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          ListStaggerEntrance(
            index: i,
            animation: _controller,
            child: widget.children[i],
          ),
      ],
    );
  }
}

/// Centered loading indicator used across shell tab screens.
class ScreenLoader extends StatelessWidget {
  const ScreenLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
