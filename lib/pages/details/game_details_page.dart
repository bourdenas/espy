import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/pages/details/game_details_content.dart';
import 'package:espy/widgets/loading_spinner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameDetailsPage extends StatelessWidget {
  const GameDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final libraryEntry =
        context.read<LibraryIndexModel>().getEntryByStringId(id);

    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection('games').doc(id).snapshots(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }

        GameEntry? gameEntry;
        if (snapshot.connectionState == ConnectionState.active) {
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            // If GameEntry is not found in Firebase this will force retrieval
            // from IGDB. Because it's a streaming connection with Firebase when
            // the document is created the page will update automatically.
            BackendApi.retrieveGameEntry(int.tryParse(id) ?? 0);

            return libraryEntry != null
                ? GameDetailsContent(libraryEntry, null)
                : LoadingSpinner(message: 'Retrieving game info');
          }

          final jsonObj = snapshot.data!.data();
          try {
            gameEntry = GameEntry.fromJson(jsonObj!);
          } catch (_) {
            if (kDebugMode) {
              print('Failed to parse GameEntry with id=$id.');
            }
            // Failures to parse a game document is typically because the document
            // format changed and the entry was not updated in the Firebase. This
            // will force a new retrieval from IGDB and produce a document with
            // the updated format.
            BackendApi.retrieveGameEntry(int.tryParse(id) ?? 0);
            return LoadingSpinner(message: 'Retrieving game info');
          }

          final gameEntrySummary = LibraryEntry.fromGameEntry(gameEntry);
          if (libraryEntry?.digest.hasDiff(gameEntrySummary.digest) ?? false) {
            context.read<UserLibraryModel>().updateEntry(libraryEntry!);
          }
        }

        if (libraryEntry == null && gameEntry == null) {
          return LoadingSpinner(message: 'Retrieving game info');
        }

        return GameDetailsContent(
          libraryEntry ?? LibraryEntry.fromGameEntry(gameEntry!),
          gameEntry,
        );
      },
    );
  }
}
