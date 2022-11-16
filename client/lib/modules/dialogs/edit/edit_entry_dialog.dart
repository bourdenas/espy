import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/pages/edit/edit_entry_content.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/material.dart';

class EditEntryDialog extends StatelessWidget {
  static Future<void> show(
    BuildContext context,
    LibraryEntry libraryEntry, {
    GameEntry? gameEntry = null,
    int? gameId = null,
  }) async {
    showDialog(
      context: context,
      builder: (context) => EditEntryDialog(libraryEntry, gameEntry, gameId),
    );
  }

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;
  final int? gameId;

  EditEntryDialog(this.libraryEntry, this.gameEntry, this.gameId);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: 500.0,
        height: 800.0,
        child: gameEntry != null
            ? EditEntryContent(
                libraryEntry: libraryEntry,
                gameEntry: gameEntry,
              )
            : buildWithFuture(context),
      ),
    );
  }

  Widget buildWithFuture(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('games')
          .doc('${gameId!}')
          .get(),
      builder: (context, snapshot) {
        final defaultContext = EditEntryContent(libraryEntry: libraryEntry);

        if (snapshot.hasError) {
          return defaultContext;
        }

        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasData) {
          return defaultContext;
        }

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final jData = (snapshot.data! as DocumentSnapshot).data()
              as Map<String, dynamic>;
          final gameEntry = GameEntry.fromJson(jData);

          return EditEntryContent(
            libraryEntry: libraryEntry,
            gameEntry: gameEntry,
          );
        }

        return defaultContext;
      },
    );
  }
}
