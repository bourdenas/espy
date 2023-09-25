import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/game_entry.dart';
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
        context.read<LibraryEntriesModel>().getEntryByStringId(id);

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
          // If GameEntry is not found in Firebase this will force retrieval
          // from IGDB. Because it's a streaming connection with Firebase when
          // the document is created the page will update automatically.
          context
              .read<UserLibraryModel>()
              .retrieveGameEntry(int.tryParse(id) ?? 0);

          return libraryEntry != null
              ? GameDetailsContent(libraryEntry, null)
              : retrieveIndicator();
        }

        final jsonObj = snapshot.data!.data();
        GameEntry? gameEntry;
        try {
          gameEntry = GameEntry.fromJson(jsonObj!);
        } catch (_) {
          // Failures to parse a game document is typically because the document
          // format changed and the entry was not updated in the Firebase. This
          // will force a new retrieval from IGDB and produce a document with
          // the updated format.
          context
              .read<UserLibraryModel>()
              .retrieveGameEntry(int.tryParse(id) ?? 0);
          return retrieveIndicator();
        }

        final gameEntrySummary = LibraryEntry.fromGameEntry(gameEntry);
        if (libraryEntry?.digest.hasDiff(gameEntrySummary.digest) ?? false) {
          print('lib: ${libraryEntry?.digest.toJson().toString()}');
          print('sum: ${gameEntrySummary.digest.toJson().toString()}');
          // TODO: update library entry.
        }

        return GameDetailsContent(
          libraryEntry ?? gameEntrySummary,
          gameEntry,
        );
      },
    );
  }

  Center retrieveIndicator() {
    return const Center(
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
}
