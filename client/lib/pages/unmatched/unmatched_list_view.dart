import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/unmatched_library_model.dart';
import 'package:espy/pages/unmatched/unmatched_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class UnmatchedListView extends StatelessWidget {
  const UnmatchedListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: Duration(milliseconds: 500),
        child: ListView.builder(
          key: Key('unmatchedListView'),
          itemCount: unmatchedEntries.length,
          itemBuilder: (context, index) {
            return UnmatchedCard(
              entry: unmatchedEntries[index],
            );
          },
        ),
      ),
    );
  }
}
