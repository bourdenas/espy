import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/igdb_game.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/pages/details/game_details_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameDetailsPage extends StatelessWidget {
  const GameDetailsPage({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  Widget build(BuildContext context) {
    final libraryEntry =
        context.watch<LibraryEntriesModel>().getEntryByStringId(id);

    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection('games').doc(id).snapshots(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data?.data() == null) {
          context
              .read<UserLibraryModel>()
              .retrieveGameEntry(int.tryParse(id) ?? 0);

          return libraryEntry != null
              ? GameDetailsContent(libraryEntry, null)
              : const Center(
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
        var gameEntry = const GameEntry(
            id: 0, name: '', category: '', igdbGame: IgdbGame(id: 0, name: ''));
        try {
          gameEntry = GameEntry.fromJson(jsonObj!);
        } catch (_) {
          context
              .read<UserLibraryModel>()
              .retrieveGameEntry(int.tryParse(id) ?? 0);
        }

        return GameDetailsContent(
          libraryEntry ?? LibraryEntry.fromGameEntry(gameEntry),
          gameEntry,
        );
      },
    );
  }
}
