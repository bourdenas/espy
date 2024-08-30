// ignore_for_file: dead_code

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenreStats extends StatefulWidget {
  const GenreStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  State<GenreStats> createState() => _GenreStatsState();
}

class _GenreStatsState extends State<GenreStats> {
  static const unknownLabel = 'Unknown';

  final genreGroupsPops = <String, int>{};
  final genresPops = <String, int>{};

  String? selectedGroup;
  String? selectedGenre;

  @override
  void initState() {
    super.initState();

    final filter = context.read<LibraryFilterModel>().filter;
    buildPops(filter);

    selectedGroup = Genres.groupOfGenre(filter.genre);
    selectedGenre = filter.genre;
  }

  void buildPops(LibraryFilter filter) {
    genreGroupsPops.clear();
    genresPops.clear();

    // Build Genre histograms.
    for (final entry in widget.libraryEntries) {
      if (entry.digest.espyGenres.isEmpty) {
        genreGroupsPops[unknownLabel] =
            (genreGroupsPops[unknownLabel] ?? 0) + 1;
      }
      for (final genre in entry.digest.espyGenres) {
        final group = Genres.groupOfGenre(genre) ?? unknownLabel;
        genreGroupsPops[group] = (genreGroupsPops[group] ?? 0) + 1;
        genresPops[genre] = (genresPops[genre] ?? 0) + 1;
      }
    }
    genresPops[unknownLabel] = genreGroupsPops[unknownLabel] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<LibraryFilterModel>().filter;
    setState(() => buildPops(filter));

    return selectedGroup == null ? genreGroupsPie() : genresPie();
  }

  Widget genreGroupsPie() {
    return EspyPieChart(
      Genres.groups.toList(),
      itemsPop: genreGroupsPops,
      unknownLabel: unknownLabel,
      onItemTap: (selectedItem) {
        context.read<RefinementModel>().refinement =
            LibraryFilter(genreGroup: selectedItem);
        setState(() => selectedGroup = selectedItem);
      },
    );
  }

  Widget genresPie() {
    final genresInGroup = Genres.genresInGroup(selectedGroup!);
    final genresSize = genresInGroup?.length ?? 0;
    final colorStep = genresSize < 6 ? 200 : 100;
    final colorStart = genresSize < 2 ? 500 : 900;

    final index = Genres.groups.toList().indexOf(selectedGroup!);
    final groupColor = defaultPalette[index % defaultPalette.length];
    final palette = [
      for (var i = 0; i < genresSize; ++i)
        groupColor[colorStart - (i * colorStep)]
    ];

    return EspyPieChart(
      genresInGroup ?? [unknownLabel],
      itemsPop: genresPops,
      unknownLabel: unknownLabel,
      selectedItem: selectedGenre,
      palette: palette,
      onItemTap: (selectedItem) {
        context.read<RefinementModel>().refinement =
            LibraryFilter(genre: selectedItem);
        setState(() => selectedGenre = selectedItem);
      },
      backLabel: selectedGroup,
      onBack: () {
        context.read<RefinementModel>().refinement = LibraryFilter();

        setState(() {
          selectedGenre = null;
          selectedGroup = null;
        });
      },
    );
  }
}
