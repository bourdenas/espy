import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimelineShelves extends StatelessWidget {
  const TimelineShelves({Key? key, this.date}) : super(key: key);

  final String? date;

  @override
  Widget build(BuildContext context) {
    final games = context.watch<FrontpageModel>().gamesByDate(date!);

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        TileShelve(
          title: date!,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          entries: games.map((digest) => LibraryEntry.fromGameDigest(digest)),
        ),
      ],
    );
  }
}
