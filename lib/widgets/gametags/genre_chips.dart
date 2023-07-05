import 'package:flutter_scatter/flutter_scatter.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/material.dart';

/// Chips used for refining genres for a `LibraryEntry`.
class GenreChips extends StatefulWidget {
  const GenreChips(this.libraryEntry, {Key? key}) : super(key: key);

  final LibraryEntry libraryEntry;

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
          if (_expandedGenre != null) _buildScatter(),
          if (_expandedGenre == null) _buildGenres(),
        ],
      ),
    );
  }

  Widget _buildScatter() {
    final genre = _expandedGenre!;
    final count = _subgenres[genre]?.length ?? 0;

    final widgets = [
      for (final label in _subgenres[genre] ?? [])
        ChoiceChip(
          label: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: [].any((e) => e == label)
                    ? Colors.white
                    : Colors.blueAccent[300]),
          ),
          selected: [].any((e) => e == label),
          selectedColor: Colors.blueAccent[200],
          onSelected: (_) => print(label),
        ),
    ];

    return Center(
      child: Scatter(
        delegate: EllipseScatterDelegate(
          start: .75,
          a: 180.0,
          b: 60.0,
          step: 1.0 / count,
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
          onPressed: () => toggleExpand(null),
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
                                BoxShadow(
                                  color: Colors.blueAccent[200]!,
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
                                              : Colors.blueAccent[300]),
                            ),
                            selected: _selectedGenres.any((e) => e == genre),
                            selectedColor: Colors.blueAccent[200],
                            onSelected: (_) => toggleExpand(genre),
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

  void toggleExpand(String? genre) {
    setState(() {
      if (genre == null || (_subgenres[genre]?.isNotEmpty ?? false)) {
        _expandedGenre = genre;
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
    'Real-Time Strategy',
    'Turn-Based Strategy',
    'Grand Strategy',
    'Isometric Tactics',
    'Turn-Based Tactics',
    'Real-Time Tactics',
  ],
};
