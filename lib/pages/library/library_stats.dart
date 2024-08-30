import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/stats/genre_stats.dart';
import 'package:flutter/material.dart';

class LibraryStats extends StatelessWidget {
  const LibraryStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    return GenreStats(libraryEntries);
  }
}
