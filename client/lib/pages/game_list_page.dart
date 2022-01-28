import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/widgets/game_list_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class GameListPage extends StatefulWidget {
  const GameListPage({required this.filter});

  final String filter;

  @override
  _GameListPageState createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  @override
  Widget build(BuildContext context) {
    final entries = context
        .watch<GameEntriesModel>()
        .getEntries(LibraryFilter(stores: {widget.filter}))
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('GOG Games'),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FadeInUp(
          from: 20,
          duration: Duration(milliseconds: 500),
          child: ListView.builder(
            key: Key('gameListView'),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return GameListCard(
                entry: entries[index],
              );
            },
          ),
        ),
      ),
    );
  }
}
