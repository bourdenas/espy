import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/search/search_results.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    return Shelve(
      title: widget.title,
      expansion: GameSearchResults(
        entries: widget.entries != null
            ? widget.entries!
            : context.watch<GameEntriesModel>().filter(widget.filter!),
        cardWidth: widget.cardWidth,
        cardAspectRatio: widget.cardAspectRatio,
      ),
      color: widget.color,
      headerLink: widget.filter != null
          ? () =>
              context.pushNamed('games', queryParams: widget.filter!.params())
          : null,
      expanded: widget.expanded,
    );
  }
}
