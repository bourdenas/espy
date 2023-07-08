import 'package:espy/modules/documents/user_tags.dart';
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
    return SizedBox(
      width: 600,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          if (_expandedGenre != null) _buildScatter(context),
          if (_expandedGenre == null) _buildGenres(),
        ],
      ),
    );
  }

  Widget _buildScatter(BuildContext context) {
    final genre = _expandedGenre!;
    final genreTags = context.watch<GameTagsModel>().genreTags;

    final widgets = [
      for (final label in _subgenres[genre] ?? [])
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
                  color: genreTags
                          .byGameId(widget.libraryEntry.id)
                          .any((e) => e.root == genre && e.name == label)
                      ? Colors.white
                      : Colors.blueAccent),
            ),
            selected: genreTags
                .byGameId(widget.libraryEntry.id)
                .any((e) => e.root == genre && e.name == label),
            selectedColor: Colors.blueAccent,
            onSelected: (selected) => selected
                ? genreTags.add(
                    Genre(root: genre, name: label), widget.libraryEntry.id)
                : genreTags.remove(
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

  Widget _buildGenres() {
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
                      for (final genre in _genres)
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
    setState(() {
      if (genre == null || (_subgenres[genre]?.isNotEmpty ?? false)) {
        _expandedGenre = genre;
      }

      if (_subgenres[genre]?.isEmpty ?? false) {
        selected
            ? context
                .read<GameTagsModel>()
                .genreTags
                .add(Genre(root: genre!, name: ''), gameId)
            : context
                .read<GameTagsModel>()
                .genreTags
                .remove(Genre(root: genre!, name: ''), gameId);
      }

      if (genre != null) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
}

const _genres = [
  'Adventure',
  'Arcade',
  'Card & Board Game',
  'MOBA',
  'Platformer',
  'Racing',
  'RPG',
  'Shooter',
  'Simulator',
  'Sport',
  'Strategy',
];

const _subgenres = {
  'Adventure': [
    'Point-and-Click',
    'Narrative Adventure',
    'Puzzle',
    'First-Person Adventure',
    'Isometric Action',
    'Action',
    'Isometric Adventure',
  ],
  'Arcade': [
    'Endless Runner',
    'Fighting',
    'Pinball',
    'Beat\'em Up',
    'Puzzle',
  ],
  'Card & Board Game': [],
  'MOBA': [],
  'Platformer': [
    'Side-Scroller',
    'Metroidvania',
    '3D Platformer',
    'Shooter Platformer',
    'Puzzle Platformer',
  ],
  'Racing': [],
  'RPG': [
    'Action RPG',
    'First-Person RPG',
    'Isometric RPG',
    'Turn-Based RPG',
    'RTwP RPG',
    'Hack & Slash',
    'JRPG',
  ],
  'Shooter': [
    'First Person Shooter',
    '3rd Person Shooter',
    'Top-Down Shooter',
    'Space Shooter',
  ],
  'Simulator': [
    'City Builder',
    'Management',
  ],
  'Sport': [],
  'Strategy': [
    '4X',
    'Turn-Based Strategy',
    'Real-Time Strategy',
    'Grand Strategy',
    'Isometric Tactics',
    'Real-Time Tactics',
    'Turn-Based Tactics',
  ],
};
