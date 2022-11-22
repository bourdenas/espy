import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/failed_entries_model.dart';
import 'package:espy/pages/failed/failed_match_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class FailedMatchListView extends StatelessWidget {
  const FailedMatchListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unmatchedEntries = context.watch<FailedEntriesModel>().entries;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: Duration(milliseconds: 500),
        child: ListView.builder(
          primary: true,
          key: Key('failedListView'),
          itemCount: unmatchedEntries.length,
          itemBuilder: (context, index) {
            return FailedMatchCard(
              entry: unmatchedEntries[index],
            );
          },
        ),
      ),
    );
  }
}
