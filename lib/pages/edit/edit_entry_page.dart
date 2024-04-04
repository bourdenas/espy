import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/pages/edit/edit_entry_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditEntryPage extends StatelessWidget {
  const EditEntryPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<LibraryEntry>(
        future: getLibraryEntry(context, id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return EditEntryContent(
              libraryEntry: snapshot.data!,
              gameId: snapshot.data!.id,
            );
          }

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
        },
      ),
    );
  }

  Future<LibraryEntry> getLibraryEntry(BuildContext context, String id) async {
    final entry = context.read<LibraryIndexModel>().getEntryByStringId(id);
    if (entry != null) {
      return entry;
    }

    final snapshot =
        await FirebaseFirestore.instance.collection('games').doc(id).get();
    if (snapshot.data() != null) {
      final jsonObj = snapshot.data();
      try {
        return LibraryEntry.fromGameEntry(GameEntry.fromJson(jsonObj!));
      } catch (_) {}
    }

    return LibraryEntry(id: 0, digest: GameDigest(id: 0, name: 'null'));
  }
}
