import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:espy/widgets/expandable_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GamePulse extends StatelessWidget {
  const GamePulse(
    this.libraryEntry,
    this.gameEntry, {
    Key? key,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;

  @override
  Widget build(BuildContext context) {
    final userRating = context.watch<UserDataModel>().rating(libraryEntry.id);
    final rating = userRating > 0
        ? userRating * 20
        : gameEntry?.steamData?.metacritic?.score ?? libraryEntry.rating;
    final score = gameEntry?.score ?? libraryEntry.rating as int;
    final popularity = gameEntry?.popularity ?? libraryEntry.digest.popularity;

    return Row(
      children: [
        criticsScore(rating, userRating),
        if (score > 0) usersScore(score),
        if (popularity > 0) popScore(popularity),
      ],
    );
  }

  Widget criticsScore(num rating, int userRating) {
    return ExpandableButton(
      offset: const Offset(0, 42),
      collapsedWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            color: rating > 0 ? Colors.amber : Colors.grey,
            size: 18.0,
          ),
          const SizedBox(width: 4.0),
          Text(
            rating > 0 ? (rating / 20.0).toStringAsFixed(1) : '--',
            style: userRating > 0 ? const TextStyle(color: Colors.green) : null,
          ),
        ],
      ),
      expansionBuilder: (context, _, onDone) {
        return _UserStarRating(libraryEntry, userRating, onDone);
      },
    );
  }

  Widget usersScore(int score) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 4),
        Icon(
          score > 60 ? Icons.thumb_up : Icons.thumb_down,
          color: switch (score) {
            0 => Colors.grey,
            (int score) when score > 80 => Colors.green,
            (int score) when score > 60 => Colors.orange,
            int() => Colors.red,
          },
          size: 18.0,
        ),
        const SizedBox(width: 4),
        Text(score > 0 ? '$score%' : '--'),
      ],
    );
  }

  Widget popScore(int popularity) {
    final formatter = NumberFormat('###,###');

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
        Text(popularity > 0 ? formatter.format(popularity) : '--'),
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
