import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/dialogs/search/search_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/game_entries_model.dart';
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
    final libraryEntry = context.read<GameEntriesModel>().getEntryById(id);

    return Actions(
      actions: {
        SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) => SearchDialog.show(context)),
        HomeIntent: CallbackAction<HomeIntent>(onInvoke: (intent) {
          Navigator.pushNamed(context, '/home');
        }),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: FutureBuilder(
            future:
                FirebaseFirestore.instance.collection('games_v2').doc(id).get(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text("Something went wrong: ${snapshot.error}"));
              }

              if (snapshot.connectionState == ConnectionState.done &&
                  !snapshot.hasData) {
                return Center(child: Text("Document does not exist"));
              }

              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final jData = (snapshot.data! as DocumentSnapshot).data()
                    as Map<String, dynamic>;
                final gameEntry = GameEntry.fromJson(jData);

                return GameDetailsContent(
                  libraryEntry: libraryEntry!,
                  gameEntry: gameEntry,
                  childPath: ids.sublist(1),
                );
              }

              return Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}
