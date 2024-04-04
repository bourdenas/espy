import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/timeline.dart';
import 'package:espy/modules/models/timeline_model.dart';
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
      future: context.watch<TimelineModel>().gamesIn(widget.year),
      builder: (BuildContext context, AsyncSnapshot<AnnualReviewDoc> snapshot) {
        return snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData
            ? AnnualGameList(review: snapshot.data!)
            : Container();
      },
    );
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

  @override
  void initState() {
    super.initState();

    final review = widget.review;
    for (final game in [
      review.releases,
      review.indies,
      review.expansions,
      review.casual,
      review.earlyAccess,
      review.debug,
    ].expand((e) => e)) {
      for (final genre in game.genres) {
        (genres[genre] ??= []).add(game.id);
      }
    }
    selectedGenres.addAll(genres.keys);
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;

    final groups = [
      (
        'Releases',
        review.releases.where((game) =>
            (selectedGenres.isEmpty ||
                game.genres.any((genre) => selectedGenres.contains(genre))) &&
            (selectedTags.isEmpty ||
                selectedTags.every((tag) => game.keywords.contains(tag))))
      ),
      if (review.indies.isNotEmpty)
        (
          'Indies',
          review.indies.where((game) =>
              (selectedGenres.isEmpty ||
                  game.genres.any((genre) => selectedGenres.contains(genre))) &&
              (selectedTags.isEmpty ||
                  selectedTags.every((tag) => game.keywords.contains(tag))))
        ),
      if (review.remasters.isNotEmpty)
        (
          'Remasters / Remakes',
          review.remasters.where((game) =>
              (selectedGenres.isEmpty ||
                  game.genres.any((genre) => selectedGenres.contains(genre))) &&
              (selectedTags.isEmpty ||
                  selectedTags.every((tag) => game.keywords.contains(tag))))
        ),
      if (review.expansions.isNotEmpty)
        (
          'Expansions',
          review.expansions.where((game) =>
              (selectedGenres.isEmpty ||
                  game.genres.any((genre) => selectedGenres.contains(genre))) &&
              (selectedTags.isEmpty ||
                  selectedTags.every((tag) => game.keywords.contains(tag))))
        ),
      if (review.casual.isNotEmpty)
        (
          'Casual',
          review.casual.where((game) =>
              (selectedGenres.isEmpty ||
                  game.genres.any((genre) => selectedGenres.contains(genre))) &&
              (selectedTags.isEmpty ||
                  selectedTags.every((tag) => game.keywords.contains(tag))))
        ),
      if (review.earlyAccess.isNotEmpty)
        (
          'Early Access',
          review.earlyAccess.where((game) =>
              (selectedGenres.isEmpty ||
                  game.genres.any((genre) => selectedGenres.contains(genre))) &&
              (selectedTags.isEmpty ||
                  selectedTags.every((tag) => game.keywords.contains(tag))))
        ),
      if (review.debug.isNotEmpty) ('Debug', review.debug),
    ];

    if (updateAvailableTags) {
      availableTags.clear();
      for (final group in groups) {
        final (_, games) = group;
        for (final game in games) {
          for (final tag in game.keywords) {
            availableTags[tag] = (availableTags[tag] ?? 0) + 1;
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
                    color: Colors.deepPurpleAccent,
                    selected: selectedGenres.contains(entry.key),
                    onSelected: (bool selected) => setState(() {
                      selected
                          ? selectedGenres.add(entry.key)
                          : selectedGenres.remove(entry.key);
                      selectedTags.clear();
                      updateAvailableTags = true;
                    }),
                    onRightClick: () => setState(() {
                      selectedGenres.clear();
                      selectedGenres.add(entry.key);
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
                    color: Colors.blueGrey,
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
