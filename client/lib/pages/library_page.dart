import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/widgets/library_headline.dart';
import 'package:espy/widgets/library_slate.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class LibraryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameEntriesModel>().getEntries(null);

    return Scaffold(
      body: SingleChildScrollView(
        key: Key('libraryScrollView'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LibraryHeadline(),
            LibrarySlate(
              text: 'GOG',
              onExpand: () => Navigator.pushNamed(context, 'gog'),
            ),
            LibrarySlate(
              text: 'Steam',
              onExpand: () => Navigator.pushNamed(context, 'steam'),
            ),
            LibrarySlate(
              text: 'Epic',
              onExpand: () => Navigator.pushNamed(context, 'epic'),
            ),
            SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
