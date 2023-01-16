import 'package:flutter/material.dart';

class LibraryHeaderDelegate extends SliverPersistentHeaderDelegate {
  LibraryHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(LibraryHeaderDelegate oldSearchBar) {
    return maxHeight != oldSearchBar.maxHeight ||
        minHeight != oldSearchBar.minHeight ||
        child != oldSearchBar.child;
  }
}
