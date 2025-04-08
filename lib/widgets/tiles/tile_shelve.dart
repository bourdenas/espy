import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/widgets/sliver_shelve.dart';
import 'package:flutter/material.dart';

class TileShelve extends StatefulWidget {
  const TileShelve({
    super.key,
    required this.title,
    required this.entries,
    this.color,
    this.filter,
    this.expanded = true,
    this.grayOutMissing = false,
  });

  final String title;
  final Iterable<LibraryEntry> entries;
  final Color? color;
  final LibraryFilter? filter;

  final bool expanded;
  final bool grayOutMissing;

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
    return SliverShelve(
      title: widget.title,
      expansion: LibraryEntriesView(
        entries: widget.entries,
        grayOutMissing: widget.grayOutMissing,
      ),
      color: widget.color,
      headerLink: widget.filter != null
          ? () => updateLibraryView(context, widget.filter!)
          : null,
      expanded: widget.expanded,
    );
  }
}
