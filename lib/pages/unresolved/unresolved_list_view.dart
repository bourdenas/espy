import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/documents/unresolved.dart';
import 'package:espy/pages/unresolved/candidates_list.dart';
import 'package:flutter/material.dart';

class UnresolvedListView extends StatelessWidget {
  const UnresolvedListView(this.unresolved, {super.key});

  final List<Unresolved> unresolved;

  @override
  Widget build(BuildContext context) {
    unresolved.sort((a, b) => a.storeEntry.title.compareTo(b.storeEntry.title));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: const Duration(milliseconds: 500),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(4),
          children: [
            for (final entry in unresolved) CandidatesList(entry),
          ],
        ),
      ),
    );
  }
}
