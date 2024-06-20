import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/game_tags_model.dart';
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
    return SlidingChip(
      label: 'Genres',
      // color: Theme.of(context).colorScheme.onSecondaryContainer,
      color: GenreGroupChip.color,
      expansion: const GameGenreGroupFilter(),
    );
  }
}

class GameGenreGroupFilter extends StatefulWidget {
  const GameGenreGroupFilter({super.key});

  @override
  State<GameGenreGroupFilter> createState() => _GameGenreGroupFilterState();
}

class _GameGenreGroupFilterState extends State<GameGenreGroupFilter> {
  @override
  void initState() {
    super.initState();
  }

  String? activeGroup;
  String? activeGenre;

  @override
  Widget build(BuildContext context) {
    return Row(
      // children: buildGenreGroups(context),
      children: (activeGroup == null)
          ? buildGenreGroups(context)
          : buildEspyGenre(context, activeGroup!),
    );
  }

  List<Widget> buildGenreGroups(BuildContext context) {
    return [
      for (final group in context.read<GameTagsModel>().genreGroups)
        if (activeGroup == null || activeGroup == group) ...[
          GenreFilterChip(
              label: group,
              color: GenreGroupChip.color,
              onClick: () => setState(() {
                    activeGroup = group;
                  })),
          const SizedBox(width: 8),
        ],
    ];
  }

  List<Widget> buildEspyGenre(BuildContext context, String genreGroup) {
    return [
      GenreFilterChip(
          label: genreGroup,
          backgroundColor: GenreGroupChip.color,
          open: true,
          onClick: () => setState(() {
                activeGroup = null;
                activeGenre = null;
                context.read<LibraryFilterModel>().filter = LibraryFilter();
              })),
      const SizedBox(width: 4),
      for (final genre
          in context.read<GameTagsModel>().espyGenreTags(genreGroup) ?? []) ...[
        EspyGenreTagChip(
          genre,
          onPressed: () {
            context.read<LibraryFilterModel>().filter =
                LibraryFilter(genres: {genre});
            setState(() {
              activeGenre = genre;
            });
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
