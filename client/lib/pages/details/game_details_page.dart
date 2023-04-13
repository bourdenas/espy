import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/pages/details/game_details_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class GameDetailsPage extends StatelessWidget {
  const GameDetailsPage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final ids = path.split(',');
    final id = ids[0];
    final libraryEntry =
        context.watch<GameEntriesModel>().getEntryByStringId(id);

    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection('games').doc(id).snapshots(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          context
              .read<GameLibraryModel>()
              .retrieveGameEntry(int.tryParse(id) ?? 0);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Retrieving game info'),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ),
          );
        }

        final jsonObj = snapshot.data!.data();
        final gameEntry = GameEntry.fromJson(jsonObj!);

        return GameDetailsContent(
          libraryEntry: libraryEntry ?? LibraryEntry.fromGameEntry(gameEntry),
          gameEntry: gameEntry,
        );
      },
    );
  }
}
