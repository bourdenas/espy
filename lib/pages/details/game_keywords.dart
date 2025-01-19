import 'package:espy/modules/documents/game_entry.dart';
import 'package:flutter/material.dart';

class GameKeywords extends StatelessWidget {
  const GameKeywords(this.gameEntry, {super.key});

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            for (final keyword in gameEntry.keywords)
              Text(
                '#$keyword',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.blueGrey),
              ),
          ],
        ),
      ),
    );
  }
}
