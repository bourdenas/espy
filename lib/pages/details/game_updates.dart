import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/steam_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class GameUpdates extends StatelessWidget {
  const GameUpdates({
    super.key,
    required this.gameEntry,
  });

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Material(
            elevation: 10.0,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    'Updates',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  )
                ],
              ),
            ),
          ),
          for (final item in gameEntry.steamData?.news ?? [])
            updateItem(context, item),
        ],
      ),
    );
  }

  Widget updateItem(BuildContext context, NewsItem item) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () async => await launchUrl(Uri.parse(item.url)),
              child: Text(
                item.title,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            Text(DateFormat('yMMMd')
                .format(DateTime.fromMillisecondsSinceEpoch(item.date * 1000))),
          ],
        ),
        subtitle: SelectableText(item.contents),
      ),
    );
  }
}
