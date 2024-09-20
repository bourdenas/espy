import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenreStats extends StatelessWidget {
  const GenreStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    final refinement = context.watch<RefinementModel>().refinement;
    final selectedGroup =
        refinement.genreGroup ?? Genres.groupOfGenre(refinement.genre);
    final selectedGenre = refinement.genre;

    // Build Genre histograms.
    Map<String, int> genreGroupsPops = {};
    Map<String, int> genresPops = {};
    int unknownPops = 0;
    for (final entry in libraryEntries) {
      if (entry.digest.espyGenres.isEmpty) {
        unknownPops += 1;
      }
      final groups = <String>{};
      for (final genre in entry.digest.espyGenres) {
        groups.add(Genres.groupOfGenre(genre) ?? unknownLabel);
        genresPops[genre] = (genresPops[genre] ?? 0) + 1;
      }
      for (final group in groups) {
        genreGroupsPops[group] = (genreGroupsPops[group] ?? 0) + 1;
      }
    }
    genreGroupsPops[unknownLabel] = unknownPops;
    genresPops[unknownLabel] = unknownPops;

    return selectedGroup == null
        ? GenreGroupPie(genreGroupsPops)
        : GenresPie(selectedGroup, selectedGenre, genresPops);
  }
}

class GenreGroupPie extends StatelessWidget {
  const GenreGroupPie(this.genreGroupsPops, {super.key});

  final Map<String, int> genreGroupsPops;

  @override
  Widget build(BuildContext context) {
    return EspyPieChart(
      Genres.groups.toList(),
      itemPops: genreGroupsPops,
      unknownLabel: unknownLabel,
      onItemTap: (selectedItem) {
        context.read<RefinementModel>().refinement =
            LibraryFilter(genreGroup: selectedItem);
      },
    );
  }
}

class GenresPie extends StatelessWidget {
  const GenresPie(this.selectedGroup, this.selectedGenre, this.genresPops,
      {super.key});

  final String selectedGroup;
  final String? selectedGenre;
  final Map<String, int> genresPops;

  @override
  Widget build(BuildContext context) {
    final genresInGroup = Genres.genresInGroup(selectedGroup);
    final genresSize = genresInGroup?.length ?? 0;
    final colorStep = genresSize < 6 ? 200 : 100;
    final colorStart = genresSize < 2 ? 500 : 900;

    final index = Genres.groups.toList().indexOf(selectedGroup);
    final groupColor = defaultPalette[index % defaultPalette.length];
    final palette = [
      for (var i = 0; i < genresSize; ++i)
        groupColor[colorStart - (i * colorStep)]
    ];

    return EspyPieChart(
      genresInGroup ?? [],
      itemPops: genresInGroup?.first != unknownLabel
          ? genresPops
          : {unknownLabel: genresPops[unknownLabel] ?? 0},
      selectedItem: selectedGenre,
      palette: palette,
      onItemTap: (selectedItem) {
        context.read<RefinementModel>().refinement =
            LibraryFilter(genre: selectedItem);
      },
      backLabel: selectedGroup,
      onBack: () => context.read<RefinementModel>().clear(),
    );
  }
}

const unknownLabel = 'Unknown';
