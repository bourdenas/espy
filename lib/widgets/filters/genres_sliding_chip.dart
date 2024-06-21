import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/filters/sliding_chip.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameGenresSlidingChip extends StatelessWidget {
  const GameGenresSlidingChip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<LibraryFilterModel>().filter;

    return SlidingChip(
      label: 'Genres',
      color: filter.genreGroup == null && filter.genre == null
          ? GenreGroupChip.color
          : null,
      backgroundColor: filter.genreGroup != null || filter.genre != null
          ? GenreGroupChip.color
          : null,
      closeIcon: Icons.close,
      expansion: const GameGenreGroupFilter(),
    );
  }
}

class GameGenreGroupFilter extends StatelessWidget {
  const GameGenreGroupFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<LibraryFilterModel>().filter;
    final activeGroup = filter.genreGroup ?? Genres.groupOfGenre(filter.genre);

    return Row(
      // children: buildGenreGroups(context),
      children: (activeGroup == null)
          ? buildGenreGroups(context)
          : buildEspyGenre(context, activeGroup),
    );
  }

  List<Widget> buildGenreGroups(BuildContext context) {
    final filter = context.watch<LibraryFilterModel>().filter;
    final activeGroup = filter.genreGroup;

    return [
      for (final group in Genres.groups)
        if (activeGroup == null || activeGroup == group) ...[
          GenreFilterChip(
              label: group,
              color: GenreGroupChip.color,
              onClick: () {
                final updated = context
                    .read<LibraryFilterModel>()
                    .filter
                    .add(LibraryFilter(genreGroup: group));
                context.read<LibraryFilterModel>().filter = updated;
              }),
          const SizedBox(width: 8),
        ],
    ];
  }

  List<Widget> buildEspyGenre(BuildContext context, String genreGroup) {
    final activeGenre = context.watch<LibraryFilterModel>().filter.genre;

    return [
      GenreFilterChip(
          label: genreGroup,
          backgroundColor: GenreGroupChip.color,
          open: true,
          onClick: () {
            final updated = context.read<LibraryFilterModel>().filter.subtract(
                LibraryFilter(genreGroup: genreGroup, genre: activeGenre));
            context.read<LibraryFilterModel>().filter = updated;
          }),
      const SizedBox(width: 4),
      for (final genre in Genres.genresInGroup(genreGroup) ?? []) ...[
        EspyGenreTagChip(
          genre,
          onPressed: () {
            final filter = context.read<LibraryFilterModel>().filter;
            final updated = activeGenre != genre
                ? filter.add(LibraryFilter(genre: genre))
                : filter.subtract(LibraryFilter(genre: genre));
            context.read<LibraryFilterModel>().filter = updated;
          },
          filled: activeGenre == genre,
        ),
        const SizedBox(width: 8),
      ],
    ];
  }
}

class GenreFilterChip extends StatelessWidget {
  const GenreFilterChip({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.openIcon = Icons.keyboard_arrow_right,
    this.closeIcon = Icons.keyboard_arrow_left,
    required this.onClick,
    this.open = false,
  });

  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData openIcon;
  final IconData closeIcon;
  final void Function() onClick;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Row(
        children: [
          Icon(
            open ? closeIcon : openIcon,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      onPressed: onClick,
    );
  }
}
