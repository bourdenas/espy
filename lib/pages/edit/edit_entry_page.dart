import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/pages/edit/edit_entry_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditEntryPage extends StatelessWidget {
  const EditEntryPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final libraryEntry =
        context.read<LibraryIndexModel>().getEntryByStringId(id);

    return Scaffold(
        appBar: AppBar(),
        body: EditEntryContent(
          libraryEntry: libraryEntry!,
          gameId: libraryEntry.id,
        ));
  }
}
