import 'package:espy/modules/models/game_entries_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class LibraryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameEntriesModel>().getEntries(null);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: TextButton(
          child: Text('Total entries in library: ${entries.length}'),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ),
    );
  }
}
