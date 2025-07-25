import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverShelve extends StatefulWidget {
  const SliverShelve({
    super.key,
    required this.title,
    required this.expansion,
    this.color,
    this.headerLink,
    this.expanded = true,
  });

  final String title;
  final Widget expansion;
  final Color? color;
  final void Function()? headerLink;

  final bool expanded;

  @override
  State<SliverShelve> createState() => _SliverShelveState();
}

class _SliverShelveState extends State<SliverShelve> {
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      pushPinnedChildren: false,
      children: [
        SliverPersistentHeader(
          pinned: true,
          floating: true,
          delegate: header(widget.title, widget.color, widget.headerLink),
        ),
        if (expanded) widget.expansion,
      ],
    );
  }

  HeaderDelegate header(
    String title,
    Color? color,
    void Function()? headerLink,
  ) {
    return HeaderDelegate(
      minHeight: 50.0,
      maxHeight: 50.0,
      child: GestureDetector(
        onTap: () => setState(() => expanded = !expanded),
        child: Material(
          elevation: 10.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(expanded ? Icons.arrow_drop_down : Icons.arrow_right),
                TextButton(
                  onPressed: headerLink,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: color,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderDelegate extends SliverPersistentHeaderDelegate {
  HeaderDelegate({
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
  bool shouldRebuild(HeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
