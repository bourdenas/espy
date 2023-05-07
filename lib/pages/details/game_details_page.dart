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
        context.watch<LibraryEntriesModel>().getEntryByStringId(id);

    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection('games').doc(id).snapshots(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          context
              .read<UserLibraryModel>()
              .retrieveGameEntry(int.tryParse(id) ?? 0);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Retrieving game info'),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ),
          );
        }

        final jsonObj = snapshot.data!.data();
        var gameEntry = const GameEntry(id: 0, name: '', category: '');
        try {
          gameEntry = GameEntry.fromJson(jsonObj!);
        } catch (_) {
          context
              .read<UserLibraryModel>()
              .retrieveGameEntry(int.tryParse(id) ?? 0);
        }

        return GameDetailsContent(
          libraryEntry: libraryEntry ?? LibraryEntry.fromGameEntry(gameEntry),
          gameEntry: gameEntry,
        );
      },
    );
  }
}
