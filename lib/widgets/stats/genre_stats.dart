import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
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
    final filter = context.watch<FilterModel>().filter.add(LibraryFilter());
    final selectedGroup =
        filter.genreGroup ?? Genres.groupOfGenre(filter.genre);
    final selectedGenre = filter.genre;

    // Build Genre histograms.
    Map<String, int> genreGroupsPops = {};
    Map<String, int> genresPops = {};
    int unknownPops = 0;
    // Create a filter model without the selected genre to keep the genre pie stable.
    filter.genreGroup = filter.genre = null;
    final model = FilterModel.create(filter, context.read<AppConfigModel>());
    for (final entry in model.processLibraryEntries(libraryEntries)) {
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

    return Row(
      children: [
        GenreGroupPie(selectedGroup, genreGroupsPops),
        if (selectedGroup != null && selectedGroup != unknownLabel)
          GenresPie(selectedGroup, selectedGenre, genresPops),
      ],
    );
  }
}

class GenreGroupPie extends StatelessWidget {
  const GenreGroupPie(this.selectedGroup, this.genreGroupsPops, {super.key});

  final String? selectedGroup;
  final Map<String, int> genreGroupsPops;

  @override
  Widget build(BuildContext context) {
    return EspyPieChart(
      Genres.groups.toList() + [unknownLabel],
      itemPops: genreGroupsPops,
      selectedItem: selectedGroup,
      onItemTap: (selectedItem) {
        final filter = context.read<FilterModel>().filter;
        filter.genre = null;
        filter.genreGroup = selectedGroup != selectedItem ? selectedItem : null;
        context.read<FilterModel>().filter = filter;
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
        final filter = LibraryFilter(genre: selectedItem);
        if (selectedGenre != selectedItem) {
          context.read<FilterModel>().add(filter);
        } else {
          context.read<FilterModel>().subtract(filter);
        }
      },
      backLabel: selectedGroup,
      onBack: () => context.read<FilterModel>().subtract(
            LibraryFilter(
              genreGroup: selectedGroup,
              genre: selectedGenre,
            ),
          ),
    );
  }
}

const unknownLabel = 'Unknown';
