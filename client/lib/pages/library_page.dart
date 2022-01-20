import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // final entries = context.watch<GameEntriesModel>().getEntries(null);
    final entries = [];

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: TextButton(
          child: Text('Total entries in library: ${entries.length}'),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/profile',
            );
          },
        ),
      ),
    );
  }
}
