import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/user_tags.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/utils/edit_distance.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Chips used for refining genres for a `LibraryEntry`.
class GenreChips extends StatefulWidget {
  const GenreChips(this.libraryEntry, this.keywords, {super.key});

  final LibraryEntry libraryEntry;
  final List<String> keywords;

  @override
  State<GenreChips> createState() => _GenreChipsState();
}

class _GenreChipsState extends State<GenreChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scatterAnimation;

  bool _subgenreOpen = false;
  String? _expandedGenre;
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
    _scatterAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
    _selectedGenres = Set.from(widget.libraryEntry.digest.genres);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_expandedGenre == null) _buildGenreChips(),
        if (_expandedGenre != null)
          // if (isMobile)
          _buildGenreTagsChips(context)
        // else ...[_buildTapToCloseFab(), _buildGenreTagsScatter(context)],
      ],
    );
  }

  Widget _buildGenreChips() {
    final tagsModel = context.watch<GameTagsModel>();
    final genreTags = tagsModel.genreTags.byGameId(widget.libraryEntry.id);
    final impliedGenres = genreTags.map((e) => tagsModel.getGenreGroup(e.name));

    final widgets = [
      for (final genre in context.read<GameTagsModel>().espyGenres)
        badges.Badge(
          showBadge: genreTags
              .where(
                  (genreTag) => tagsModel.getGenreGroup(genreTag.name) == genre)
              .isNotEmpty,
          badgeContent: Text(
              '${genreTags.where((genreTag) => tagsModel.getGenreGroup(genreTag.name) == genre).length}'),
          position: badges.BadgePosition.topEnd(top: -16, end: -8),
          badgeAnimation: const badges.BadgeAnimation.scale(),
          badgeStyle: badges.BadgeStyle(
            badgeColor: GenreTagChip.color,
            shape: badges.BadgeShape.circle,
          ),
          child: _TagSelectionChip(
            label: genre,
            color: GenreChip.color,
            hasHalo: widget.libraryEntry.digest.genres.contains(genre),
            isSelected: _selectedGenres.any((e) => e == genre) ||
                impliedGenres.any((e) => e == genre),
            onSelected: (selected) => toggleExpand(
              context,
              selected,
              genre,
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

  Widget _buildGenreTagsChips(BuildContext context) {
    final genre = _expandedGenre!;
    final tagsModel = context.watch<GameTagsModel>();

    final widgets = [
      for (final label in tagsModel.espyGenreTags(genre) ?? [])
        _TagSelectionChip(
          label: label,
          color: GenreTagChip.color,
          hasHalo: matchInDict(label, widget.keywords),
          isSelected: tagsModel.genreTags.byGameId(widget.libraryEntry.id).any(
              (e) =>
                  tagsModel.getGenreGroup(e.name) == genre && e.name == label),
          onSelected: (selected) => selected
              ? tagsModel.genreTags
                  .add(Genre(name: label), widget.libraryEntry.id)
              : tagsModel.genreTags
                  .remove(Genre(name: label), widget.libraryEntry.id),
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
        _expandedGenre == null ? 0.7 : 1.0,
        _expandedGenre == null ? 0.7 : 1.0,
        1.0,
      ),
      duration: const Duration(milliseconds: 250),
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      child: AnimatedOpacity(
        opacity: _expandedGenre == null ? 0.0 : 1.0,
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
      _expandedGenre = genre;

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
