import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/failed_model.dart';
import 'package:espy/pages/failed/failed_match_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FailedMatchListView extends StatelessWidget {
  const FailedMatchListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unmatchedEntries = context.watch<FailedModel>().entries;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: const Duration(milliseconds: 500),
        child: ListView.builder(
          primary: true,
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
