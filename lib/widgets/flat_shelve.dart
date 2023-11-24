import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:flutter/material.dart';

/// An equivalent to TileShelve that is not collapsable and returns a Widget instead of Slivers.
class FlatShelve extends StatelessWidget {
  const FlatShelve({
    Key? key,
    required this.title,
    required this.entries,
    this.color,
  }) : super(key: key);

  final String title;
  final Iterable<LibraryEntry> entries;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: 10.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
        CustomScrollView(
          primary: false,
          shrinkWrap: true,
          slivers: [
            LibraryEntriesView(entries: entries),
          ],
        )
      ],
    );
  }
}
