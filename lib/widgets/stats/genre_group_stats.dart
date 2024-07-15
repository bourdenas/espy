import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenreGroupStats extends StatelessWidget {
  const GenreGroupStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    if (libraryEntries.isEmpty) {
      return Container();
    }

    const unknownLabel = 'Unknown';
    final genreGroupsPop = <String, int>{};
    for (final entry in libraryEntries) {
      if (entry.digest.espyGenres.isEmpty) {
        genreGroupsPop[unknownLabel] = (genreGroupsPop[unknownLabel] ?? 0) + 1;
      }
      for (final genre in entry.digest.espyGenres) {
        final group = Genres.groupOfGenre(genre) ?? unknownLabel;
        genreGroupsPop[group] = (genreGroupsPop[group] ?? 0) + 1;
      }
    }

    return EspyPieChart(
      Genres.groups.toList(),
      genreGroupsPop,
      unknownLabel: unknownLabel,
      onItemTap: (selectedItem) {
        final filter = context.read<LibraryFilterModel>().filter;
        final updated = filter.add(LibraryFilter(genreGroup: selectedItem));
        context.read<LibraryFilterModel>().filter = updated;
      },
    );
  }
}
