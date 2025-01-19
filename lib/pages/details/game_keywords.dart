import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/models/keyword_mapping.dart';
import 'package:flutter/material.dart';

class GameKeywords extends StatelessWidget {
  const GameKeywords(this.gameEntry, {super.key});

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(context),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                for (final keyword in gameEntry.keywords)
                  InkWell(
                    onTap: () {},
                    child: Text(
                      '#$keyword',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: keywordsPalette[
                              Keywords.groupOfKeyword(keyword)]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget header(BuildContext context) {
    return Material(
      elevation: 10.0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          children: [
            InkWell(
              onTap: () {},
              child: Text(
                'Keywords',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
