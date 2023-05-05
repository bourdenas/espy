import 'package:espy/modules/models/app_config_model.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

class Shelve extends StatefulWidget {
  const Shelve({
    Key? key,
    required this.title,
    required this.expansion,
    this.color,
    this.headerLink,
    this.expanded = true,
  }) : super(key: key);

  final String title;
  final Widget expansion;
  final Color? color;
  final void Function()? headerLink;

  final bool expanded;

  @override
  State<Shelve> createState() => _ShelveState();
}

class _ShelveState extends State<Shelve> {
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      pushPinnedChildren: true,
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
          color: AppConfigModel.foregroundColor,
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
