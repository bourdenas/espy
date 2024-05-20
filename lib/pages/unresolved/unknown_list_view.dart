import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/unresolved_model.dart';
import 'package:espy/pages/unresolved/unknown_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnknownListView extends StatelessWidget {
  const UnknownListView({super.key});

  @override
  Widget build(BuildContext context) {
    final unmatchedEntries = context.watch<UnresolvedModel>().unknown;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: const Duration(milliseconds: 500),
        child: ListView.builder(
          primary: true,
          itemCount: unmatchedEntries.length,
          itemBuilder: (context, index) {
            return UnknownCard(
              entry: unmatchedEntries[index],
            );
          },
        ),
      ),
    );
  }
}
