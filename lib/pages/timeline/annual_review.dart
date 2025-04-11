import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/calendar.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/years_model.dart';
import 'package:espy/pages/library/library_page.dart';
import 'package:espy/widgets/gametags/espy_chips.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnnualReview extends StatefulWidget {
  const AnnualReview({super.key, required this.year});

  final String year;

  @override
  State<AnnualReview> createState() => _AnnualReviewState();
}

class _AnnualReviewState extends State<AnnualReview> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.watch<YearsModel>().gamesIn(widget.year),
      builder: (BuildContext context, AsyncSnapshot<AnnualReviewDoc> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          // ? AnnualGameList(review: snapshot.data!)
          context.read<CustomViewModel>().digests = snapshot.data!.releases;
          return AnnualLibaryView(review: snapshot.data!);
        }
        return Container();
      },
    );
  }
}

class AnnualLibaryView extends StatelessWidget {
  const AnnualLibaryView({super.key, required this.review});

  final AnnualReviewDoc review;

  @override
  Widget build(BuildContext context) {
    return LibraryPage(
        title: 'Releases in ${review.releases.first.releaseYear}');
  }
}

class AnnualGameList extends StatefulWidget {
  const AnnualGameList({
    super.key,
    required this.review,
  });

  final AnnualReviewDoc review;

  @override
  State<AnnualGameList> createState() => _AnnualGameListState();
}

class _AnnualGameListState extends State<AnnualGameList> {
  final genres = HashMap<String, List<int>>();

  final selectedGenres = HashSet<String>();
  final selectedTags = HashSet<String>();
  final availableTags = HashMap<String, int>();
  bool updateAvailableTags = true;

  final bannedTags = HashSet<String>();

  @override
  void initState() {
    super.initState();

    bannedTags.addAll([
      // Genres
      '2D Platformer',
      'Action Roguelike',
      'Action RPG',
      'Action-Adventure',
      'Action',
      'Adventure',
      'Arcade',
      'City Builder',
      'Exploration',
      'FPS',
      'Hack and Slash',
      'Indie',
      'JRPG',
      'Platformer',
      'Point & Click',
      'Puzzle Platformer',
      'RPG',
      'Shooter',
      'Side Scroller',
      'Simulation',
      'Sports',
      'Strategy RPG',
      'Strategy',
      'Tactical RPG',
      'Tactical',
      'Turn-Based Strategy',
      'Turn-Based Tactics',
      // Playing Mode
      'Singleplayer',
      'Multiplayer',
      'Local Multiplayer',
      'Controller',
      // Ambience
      'Atmospheric',
      'Cinematic',
      'Colorful',
      'Comedy',
      'Cute',
      'Dark',
      'Detective',
      'Drama',
      'Emotional',
      'Family Friendly',
      'Fantasy',
      'Funny',
      'Futuristic',
      'Gore',
      'Mystery',
      'Realistic',
      'Relaxing',
      'Story Rich',
      'Stylized',
      'Violent',
      // Functions
      'Multiple Endings',
      'Open World',
      'Sandbox',
      'Difficult',
      'Combat',
      'Base Building',
      'Procedural Generation',
      'Great Soundtrack',
      'Resource Management',
      'Character Customization',
      // View
      '2.5D',
      '2D',
      '3D',
      'Building',
      'Choices Matter',
      'First-Person',
      'Isometric',
      'Third Person',
      'Top Down',
      'Top-Down',
      //
      'Early Access',
      'Retro',
      'Female Protagonist',
      'Soundtrack',
      'Old School',
      // Random
      'Military',
      'Lore-Rich',
      'Magic',
      'Linear',
      '1980s',
      'Economy',
    ]);

    final review = widget.review;
    for (final game in [
      review.releases,
      review.indies,
      review.remasters,
      review.expansions,
      review.casual,
      review.earlyAccess,
      review.debug,
    ].expand((e) => e)) {
      for (final genre in game.espyGenres) {
        (genres[genre] ??= []).add(game.id);
      }
      if (game.espyGenres.isEmpty) {
        (genres['Unknown'] ??= []).add(game.id);
      }
    }
    // selectedGenres.addAll(genres.keys);
  }

  bool selectionCriteria(game) =>
      (
          // No genre is selected.
          selectedGenres.isEmpty ||
              // Game contains all selected genres
              selectedGenres
                  .every((genre) => game.espyGenres.contains(genre)) ||
              // Unknown genre is selected and game has no assigned genres
              selectedGenres.contains('Unknown') &&
                  selectedGenres.length == 1 &&
                  game.espyGenres.isEmpty) &&
      (selectedTags.isEmpty ||
          selectedTags.every((tag) => game.keywords.contains(tag)));

  @override
  Widget build(BuildContext context) {
    final review = widget.review;

    final groups = [
      ('Releases', review.releases.where(selectionCriteria)),
      if (review.indies.isNotEmpty)
        ('Indies', review.indies.where(selectionCriteria)),
      if (review.remasters.isNotEmpty)
        ('Remasters / Remakes', review.remasters.where(selectionCriteria)),
      if (review.expansions.isNotEmpty)
        ('Expansions', review.expansions.where(selectionCriteria)),
      if (review.casual.isNotEmpty)
        ('Casual', review.casual.where(selectionCriteria)),
      if (review.earlyAccess.isNotEmpty)
        ('Early Access', review.earlyAccess.where(selectionCriteria)),
      if (review.debug.isNotEmpty)
        ('Debug', review.debug.where(selectionCriteria)),
    ];

    if (updateAvailableTags) {
      availableTags.clear();
      for (final group in groups) {
        final (_, games) = group;
        for (final game in games) {
          for (final tag in game.keywords) {
            if (!bannedTags.contains(tag)) {
              availableTags[tag] = (availableTags[tag] ?? 0) + 1;
            }
          }
        }
      }
      updateAvailableTags = false;
    }

    return Column(
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final entry
                  in genres.entries.toList()
                    ..sort((a, b) => -a.value.length.compareTo(b.value.length)))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: EspyFilterChip(
                    label: '${entry.key} (${entry.value.length})',
                    color: EspyGenreChip.color,
                    selected: selectedGenres.contains(entry.key),
                    onSelected: (bool selected) => setState(() {
                      selectedGenres.clear();
                      if (selected) {
                        selectedGenres.add(entry.key);
                      }
                      selectedTags.clear();
                      updateAvailableTags = true;
                    }),
                    onRightClick: () => setState(() {
                      final selected = !selectedGenres.contains(entry.key);
                      selected
                          ? selectedGenres.add(entry.key)
                          : selectedGenres.remove(entry.key);
                      selectedTags.clear();
                      updateAvailableTags = true;
                    }),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final entry
                  in availableTags.entries.toList()
                    ..sort((a, b) => -a.value.compareTo(b.value)))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: EspyFilterChip(
                    label: '${entry.key} (${entry.value})',
                    color: KeywordChip.color,
                    selected: selectedTags.contains(entry.key),
                    onSelected: (bool selected) => setState(() {
                      selected
                          ? selectedTags.add(entry.key)
                          : selectedTags.remove(entry.key);
                    }),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            primary: true,
            shrinkWrap: true,
            slivers: [
              for (final (label, digests) in groups)
                TileShelve(
                  title: '$label (${digests.length})',
                  color: Colors.grey,
                  entries: digests
                      .map((digest) => LibraryEntry.fromGameDigest(digest)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class EspyFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback? onRightClick;

  const EspyFilterChip({
    super.key,
    required this.label,
    required this.color,
    required this.onSelected,
    this.selected = false,
    this.onRightClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: onRightClick,
      child: FilterChip(
        label: Text(label),
        selectedColor: color,
        onSelected: (bool selected) {
          onSelected(selected);
        },
        selected: selected,
      ),
    );
  }
}
