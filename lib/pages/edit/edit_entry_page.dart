import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/pages/edit/edit_entry_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class EditEntryPage extends StatelessWidget {
  const EditEntryPage({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final libraryEntry =
        context.read<GameEntriesModel>().getEntryByStringId(id);

    return Scaffold(
        appBar: AppBar(),
        body: EditEntryContent(
          libraryEntry: libraryEntry!,
          gameId: libraryEntry.id,
        ));
  }
}
