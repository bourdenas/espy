import 'package:espy/modules/models/unmatched_entries_model.dart';
import 'package:espy/widgets/library/store_entry_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnmatchedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView(
        restorationId: 'list_view_unmatched_game_entries_offset',
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: context
            .watch<UnmatchedEntriesModel>()
            .entries
            .map(
              (storeEntry) => ListTile(
                title: Row(children: [
                  Text(storeEntry.title),
                ]),
                subtitle: Text('${storeEntry.store}'),
                onTap: () async =>
                    await StoreEntryEditDialog.show(context, storeEntry),
              ),
            )
            .toList(),
      ),
    );
  }
}
