import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:espy/widgets/expandable_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GamePulse extends StatelessWidget {
  const GamePulse(
    this.libraryEntry,
    this.gameEntry, {
    super.key,
  });

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;

  @override
  Widget build(BuildContext context) {
    final userRating = context.watch<UserDataModel>().rating(libraryEntry.id);
    final tier = gameEntry?.scores.tier ?? libraryEntry.tier;
    final thumbs = gameEntry?.scores.thumbs ?? libraryEntry.thumbs;
    final popularity = gameEntry?.scores.popularity ?? libraryEntry.popularity;
    final metacritic = userRating > 0
        ? userRating * 20
        : gameEntry?.scores.metacritic ?? libraryEntry.metacritic;

    return Row(
      children: [
        criticsScore(metacritic, userRating),
        if (thumbs > 0) steamScore(tier, thumbs),
        if (popularity > 0) popScore(popularity),
      ],
    );
  }

  Widget criticsScore(int metacritic, int userRating) {
    return ExpandableButton(
      offset: const Offset(0, 42),
      collapsedWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            color: metacritic > 0 ? Colors.amber : Colors.grey,
            size: 18.0,
          ),
          const SizedBox(width: 4.0),
          Text(
            metacritic > 0 ? (metacritic / 20.0).toStringAsFixed(1) : '--',
            style: userRating > 0 ? const TextStyle(color: Colors.green) : null,
          ),
        ],
      ),
      expansionBuilder: (context, _, onDone) {
        return _UserStarRating(libraryEntry, userRating, onDone);
      },
    );
  }

  Widget steamScore(int tier, int thumbs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 4),
        Icon(
          switch (tier) {
            9 || 8 || 7 => Icons.thumb_up,
            6 || 5 => Icons.thumbs_up_down,
            4 || 3 || 2 || 1 => Icons.thumb_down,
            _ => Icons.question_mark,
          },
          color: switch (tier) {
            9 => Colors.green,
            8 => Colors.green[200],
            7 => Colors.yellow,
            6 => Colors.yellow,
            5 => Colors.orange,
            4 => Colors.orange,
            3 => Colors.red[200],
            2 => Colors.red,
            1 => Colors.red[800],
            _ => Colors.white70,
          },
          size: 18.0,
        ),
        const SizedBox(width: 4),
        Text(thumbs > 0 ? '$thumbs%' : '--'),
      ],
    );
  }

  Widget popScore(int popularity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 8),
        Icon(
          Icons.people,
          color: popularity > 0 ? Colors.blueAccent : Colors.grey,
          size: 18.0,
        ),
        const SizedBox(width: 4),
        Text(popularity >= 1000
            ? '${popularity ~/ 1000}K'
            : popularity.toString()),
      ],
    );
  }
}

class _UserStarRating extends StatefulWidget {
  const _UserStarRating(
    this.libraryEntry,
    this.userRating,
    this.onDone,
  );

  final LibraryEntry libraryEntry;
  final int userRating;
  final Function() onDone;

  @override
  State<_UserStarRating> createState() => _UserStarRatingState();
}

class _UserStarRatingState extends State<_UserStarRating> {
  int selected = 0;

  @override
  void initState() {
    super.initState();

    selected = widget.userRating;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            for (final i in List.generate(5, (i) => i))
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    selected = i + 1;
                  });
                },
                onExit: (_) {
                  setState(() {
                    selected = widget.userRating;
                  });
                },
                child: GestureDetector(
                  onTap: () {
                    widget.onDone();
                    context.read<UserDataModel>().updateRating(
                        widget.libraryEntry.id,
                        i + 1 != widget.userRating ? i + 1 : 0);
                  },
                  child: Icon(
                    selected > i ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
