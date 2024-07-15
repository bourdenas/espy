// ignore_for_file: dead_code

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenreStats extends StatelessWidget {
  const GenreStats(this.libraryEntries, this.filter, {super.key});

  final Iterable<LibraryEntry> libraryEntries;
  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    final genreGroup = filter.genreGroup ?? Genres.groupOfGenre(filter.genre);
    if (libraryEntries.isEmpty || genreGroup == null) {
      return Container();
    }

    const unknownLabel = '';
    final genresPop = <String, int>{};
    for (final entry in libraryEntries) {
      if (entry.digest.espyGenres.isEmpty) {
        genresPop[unknownLabel] = (genresPop[unknownLabel] ?? 0) + 1;
      }
      for (final genre in entry.digest.espyGenres) {
        if (Genres.groupOfGenre(genre) == genreGroup) {
          genresPop[genre] = (genresPop[genre] ?? 0) + 1;
        }
      }
    }

    final genresSize = Genres.genresInGroup(genreGroup)?.length ?? 0;
    final colorStep = genresSize < 6 ? 200 : 100;
    final colorStart = genresSize < 2 ? 500 : 900;

    final index = Genres.groups.toList().indexOf(genreGroup);
    final groupColor = defaultPalette[index % defaultPalette.length];
    final palette = [
      for (var i = 0; i < genresSize; ++i)
        groupColor[colorStart - (i * colorStep)]
    ];

    return EspyPieChart(
      Genres.genresInGroup(genreGroup) ?? [unknownLabel],
      genresPop,
      palette: palette,
      onItemTap: (selectedItem) {
        final updated = filter.add(LibraryFilter(genre: selectedItem));
        context.read<LibraryFilterModel>().filter = updated;
      },
      backLabel: genreGroup,
      onBack: () {
        if (filter.genre == null) {
          filter.genreGroup = null;
        }
        filter.genre = null;
        context.read<LibraryFilterModel>().filter = filter;
      },
    );
  }
}
