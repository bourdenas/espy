import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
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
    this.pushNavigation = true,
  }) : super(key: key);

  final String title;
  final Color? color;
  final LibraryFilter? filter;
  final Iterable<LibraryEntry>? entries;

  final double cardWidth;
  final double cardAspectRatio;
  final bool expanded;
  final bool pushNavigation;

  @override
  State<TileShelve> createState() => _TileShelveState();
}

class _TileShelveState extends State<TileShelve> {
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    return Shelve(
      title: widget.title,
      expansion: LibraryEntriesView(
        entries: widget.entries != null
            ? widget.entries!
            : context.watch<LibraryEntriesModel>().filter(widget.filter!).all,
        cardWidth: widget.cardWidth,
        cardAspectRatio: widget.cardAspectRatio,
        pushNavigation: widget.pushNavigation,
      ),
      color: widget.color,
      headerLink: widget.filter != null
          ? () => context.pushNamed('games',
              queryParameters: widget.filter!.params())
          : null,
      expanded: widget.expanded,
    );
  }
}
