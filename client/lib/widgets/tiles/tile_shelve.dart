
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/search/search_results.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TileShelve extends StatefulWidget {
  const TileShelve({
    Key? key,
    required this.title,
    this.color,
    this.filter,
    this.entries,
    this.cardWidth = 250,
    this.cardAspectRatio = .75,
    this.expanded = true,
  }) : super(key: key);

  final String title;
  final Color? color;
  final LibraryFilter? filter;
  final Iterable<LibraryEntry>? entries;

  final double cardWidth;
  final double cardAspectRatio;
  final bool expanded;

  @override
  State<TileShelve> createState() => _TileShelveState(expanded);
}

class _TileShelveState extends State<TileShelve> {
  _TileShelveState(this.expanded);

  bool expanded;

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      pushPinnedChildren: true,
      children: [
        SliverPersistentHeader(
          pinned: true,
          floating: true,
          delegate: header(
            context,
            widget.title,
            widget.color,
            widget.filter,
          ),
        ),
        if (expanded)
          GameSearchResults(
            entries: widget.entries != null
                ? widget.entries!
                : context.watch<GameEntriesModel>().filter(widget.filter!),
            cardWidth: widget.cardWidth,
            cardAspectRatio: widget.cardAspectRatio,
          ),
      ],
    );
  }

  HeaderDelegate header(
      BuildContext context, String title, Color? color, LibraryFilter? filter) {
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
                  onPressed: filter != null
                      ? () => context.pushNamed('games',
                          queryParams: filter.params())
                      : null,
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
  bool shouldRebuild(HeaderDelegate oldHeader) {
    return maxHeight != oldHeader.maxHeight ||
        minHeight != oldHeader.minHeight ||
        child != oldHeader.child;
  }
}
