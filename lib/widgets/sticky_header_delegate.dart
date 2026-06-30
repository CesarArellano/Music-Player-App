import 'package:flutter/material.dart';
import 'package:focus_music_player/theme/app_theme.dart';

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const StickyHeaderDelegate({required this.child, this.height = 57.0});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: overlapsContent ? AppTheme.surfaceColor : Colors.transparent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(StickyHeaderDelegate old) => false;
}
