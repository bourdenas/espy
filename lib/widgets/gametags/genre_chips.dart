import 'package:espy/modules/documents/user_tags.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/utils/edit_distance.dart';
import 'package:flutter_scatter/flutter_scatter.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Chips used for refining genres for a `LibraryEntry`.
class GenreChips extends StatefulWidget {
  const GenreChips(this.libraryEntry, this.keywords, {Key? key})
      : super(key: key);

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
          if (isMobile)
            _buildGenreTagsChips(context)
          else ...[_buildTapToCloseFab(), _buildGenreTagsScatter(context)],
      ],
    );
  }

  Widget _buildGenreTagsChips(BuildContext context) {
    final genre = _expandedGenre!;
    final tagsModel = context.watch<GameTagsModel>();

    return Column(
      children: [
        Padding(
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
                    children: [
                      for (final label in tagsModel.espyGenreTags(genre) ?? [])
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              // Halo effect for suggesting a genre.
                              if (matchInDict(label, widget.keywords))
                                const BoxShadow(
                                  color: Colors.blueAccent,
                                  blurRadius: 6.0,
                                  spreadRadius: 2.0,
                                ),
                            ],
                          ),
                          child: ChoiceChip(
                            label: Text(
                              label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      color: tagsModel.genreTags
                                              .byGameId(widget.libraryEntry.id)
                                              .any((e) =>
                                                  e.root == genre &&
                                                  e.name == label)
                                          ? Colors.white
                                          : Colors.blueAccent),
                            ),
                            selected: tagsModel.genreTags
                                .byGameId(widget.libraryEntry.id)
                                .any((e) => e.root == genre && e.name == label),
                            selectedColor: Colors.blueAccent,
                            onSelected: (selected) => selected
                                ? tagsModel.genreTags.add(
                                    Genre(root: genre, name: label),
                                    widget.libraryEntry.id)
                                : tagsModel.genreTags.remove(
                                    Genre(root: genre, name: label),
                                    widget.libraryEntry.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildTapToCloseFab(),
      ],
    );
  }

  Widget _buildGenreTagsScatter(BuildContext context) {
    final genre = _expandedGenre!;
    final tagsModel = context.watch<GameTagsModel>();

    final widgets = [
      for (final label in tagsModel.espyGenreTags(genre) ?? [])
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              // Halo effect for suggesting a sub-genre.
              if (matchInDict(label, widget.keywords))
                const BoxShadow(
                  color: Colors.blueAccent,
                  blurRadius: 6.0,
                  spreadRadius: 2.0,
                ),
            ],
          ),
          child: ChoiceChip(
            label: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: tagsModel.genreTags
                          .byGameId(widget.libraryEntry.id)
                          .any((e) => e.root == genre && e.name == label)
                      ? Colors.white
                      : Colors.blueAccent),
            ),
            selected: tagsModel.genreTags
                .byGameId(widget.libraryEntry.id)
                .any((e) => e.root == genre && e.name == label),
            selectedColor: Colors.blueAccent,
            onSelected: (selected) => selected
                ? tagsModel.genreTags.add(
                    Genre(root: genre, name: label), widget.libraryEntry.id)
                : tagsModel.genreTags.remove(
                    Genre(root: genre, name: label), widget.libraryEntry.id),
          ),
        ),
    ];

    return Center(
      child: Scatter(
        delegate: EllipseScatterDelegate(
          start: .75,
          a: 180.0,
          b: 60.0,
          step: 1.0 / widgets.length,
        ),
        children: widgets,
      ),
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
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildGenreChips() {
    final impliedGenres = context
        .watch<GameTagsModel>()
        .genreTags
        .byGameId(widget.libraryEntry.id)
        .map((e) => e.root);

    return Column(
      children: [
        Padding(
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
                    children: [
                      for (final genre
                          in context.read<GameTagsModel>().espyGenres)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              // Halo effect for suggesting a genre.
                              if (widget.libraryEntry.digest.genres
                                  .contains(genre))
                                const BoxShadow(
                                  color: Colors.blueAccent,
                                  blurRadius: 6.0,
                                  spreadRadius: 2.0,
                                ),
                            ],
                          ),
                          child: ChoiceChip(
                            label: Text(
                              genre,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      color:
                                          _selectedGenres.any((e) => e == genre)
                                              ? Colors.white
                                              : Colors.blueAccent),
                            ),
                            selected: _selectedGenres.any((e) => e == genre) ||
                                impliedGenres.any((e) => e == genre),
                            selectedColor: Colors.blueAccent,
                            onSelected: (selected) => toggleExpand(
                              context,
                              selected,
                              genre,
                              widget.libraryEntry.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void toggleExpand(
      BuildContext context, bool selected, String? genre, int gameId) {
    final tagsModel = context.read<GameTagsModel>();
    setState(() {
      if (genre == null ||
          (tagsModel.espyGenreTags(genre)?.isNotEmpty ?? false)) {
        _expandedGenre = genre;
      } else if (tagsModel.espyGenreTags(genre)?.isEmpty ?? false) {
        selected
            ? tagsModel.genreTags.add(Genre(root: genre, name: ''), gameId)
            : tagsModel.genreTags.remove(Genre(root: genre, name: ''), gameId);
      }

      if (genre != null) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
}
