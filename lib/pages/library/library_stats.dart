import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/genre_group_stats.dart';
import 'package:espy/widgets/stats/genre_stats.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryStats extends StatelessWidget {
  const LibraryStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<LibraryFilterModel>().filter;

    return filter.genreGroup == null
        ? GenreGroupStats(libraryEntries)
        : GenreStats(libraryEntries, filter);
  }
}
