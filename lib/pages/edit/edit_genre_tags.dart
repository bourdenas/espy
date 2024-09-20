import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/user_annotations.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/genres_mapping.dart';
import 'package:espy/utils/edit_distance.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget used for manual genre selection in game entry edit dialog.
class EditGenreTags extends StatefulWidget {
  const EditGenreTags(this.libraryEntry, this.keywords, {super.key});

  final LibraryEntry libraryEntry;
  final List<String> keywords;

  @override
  State<EditGenreTags> createState() => _EditGenreTagsState();
}

class _EditGenreTagsState extends State<EditGenreTags>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _subgenreOpen = false;
  String? _expandedGenreGroup;
  Set<String> _selectedGenres = {};

  @override
  void initState() {
    super.initState();

    _subgenreOpen = false;
    _controller = AnimationController(
      value: _subgenreOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _selectedGenres = Set.from(widget.libraryEntry.digest.igdbGenres);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_expandedGenreGroup == null)
          _buildGenreChips()
        else
          _buildManualGenreChips(context),
      ],
    );
  }

  Widget _buildGenreChips() {
    final tagsModel = context.watch<GameTagsModel>();
    final manualGenres =
        tagsModel.manualGenres.byGameId(widget.libraryEntry.id);
    // TODO: Collect the implied GenreGroups from the user tags.
    final impliedGenres = [];

    final widgets = [
      for (final genreGroup in Genres.groups)
        badges.Badge(
          showBadge: manualGenres
              .where((manualGenre) =>
                  Genres.groupOfGenre(
                      Genres.genreFromLabel(manualGenre.label)) ==
                  genreGroup)
              .isNotEmpty,
          badgeContent: Text(
              '${manualGenres.where((genreTag) => Genres.groupOfGenre(Genres.genreFromLabel(genreTag.label)) == genreGroup).length}'),
          position: badges.BadgePosition.topEnd(top: -16, end: -8),
          badgeAnimation: const badges.BadgeAnimation.scale(),
          badgeStyle: badges.BadgeStyle(
            badgeColor: ManualGenreChip.color,
            shape: badges.BadgeShape.circle,
          ),
          child: _TagSelectionChip(
            label: genreGroup,
            color: GenreGroupChip.color,
            hasHalo: widget.libraryEntry.digest.igdbGenres.contains(genreGroup),
            isSelected: _selectedGenres.any((e) => e == genreGroup) ||
                impliedGenres.any((e) => e == genreGroup),
            onSelected: (selected) => toggleExpand(
              context,
              selected,
              genreGroup,
              widget.libraryEntry.id,
            ),
          ),
        ),
    ];

    return Column(
      children: [
        _TagsWarp(children: widgets),
      ],
    );
  }

  Widget _buildManualGenreChips(BuildContext context) {
    final genreGroup = _expandedGenreGroup!;
    final tagsModel = context.watch<GameTagsModel>();

    final widgets = [
      for (final genreLabel in (Genres.genresInGroup(genreGroup) ?? [])
          .map((e) => Genres.genreLabel(e)))
        _TagSelectionChip(
          label: genreLabel,
          color: ManualGenreChip.color,
          hasHalo: matchInDict(genreLabel, widget.keywords),
          isSelected: tagsModel.manualGenres
              .byGameId(widget.libraryEntry.id)
              .any((e) => e.label == genreLabel),
          onSelected: (selected) => selected
              ? tagsModel.manualGenres
                  .add(Genre(label: genreLabel), widget.libraryEntry.id)
              : tagsModel.manualGenres
                  .remove(Genre(label: genreLabel), widget.libraryEntry.id),
        ),
    ];

    return Column(
      children: [
        _TagsWarp(children: widgets),
        _buildTapToCloseFab(),
      ],
    );
  }

  Widget _buildTapToCloseFab() {
    return AnimatedContainer(
      transformAlignment: Alignment.center,
      transform: Matrix4.diagonal3Values(
        _expandedGenreGroup == null ? 0.7 : 1.0,
        _expandedGenreGroup == null ? 0.7 : 1.0,
        1.0,
      ),
      duration: const Duration(milliseconds: 250),
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      child: AnimatedOpacity(
        opacity: _expandedGenreGroup == null ? 0.0 : 1.0,
        curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
        duration: const Duration(milliseconds: 250),
        child: FloatingActionButton(
          mini: true,
          backgroundColor: const Color(0x00FFFFFF),
          onPressed: () =>
              toggleExpand(context, false, null, widget.libraryEntry.id),
          child: const Icon(
            Icons.close,
            size: 24,
          ),
        ),
      ),
    );
  }

  void toggleExpand(
      BuildContext context, bool selected, String? genre, int gameId) {
    setState(() {
      _expandedGenreGroup = genre;

      if (genre != null) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
}

class _TagsWarp extends StatelessWidget {
  const _TagsWarp({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16.0,
                runSpacing: 16.0,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagSelectionChip extends StatelessWidget {
  const _TagSelectionChip({
    required this.label,
    required this.color,
    this.hasHalo = false,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final bool hasHalo;
  final bool isSelected;
  final void Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          // Halo effect for suggesting a genre.
          if (hasHalo)
            BoxShadow(
              color: color,
              blurRadius: 6.0,
              spreadRadius: 8.0,
            ),
        ],
      ),
      child: ChoiceChip(
        label: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: isSelected ? Colors.white : color),
        ),
        selected: isSelected,
        selectedColor: color,
        onSelected: onSelected,
      ),
    );
  }
}
