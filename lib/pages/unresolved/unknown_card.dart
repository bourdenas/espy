import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/widgets/cards/cover.dart';
import 'package:espy/widgets/cards/footers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UnknownCard extends StatelessWidget {
  const UnknownCard(this.entry, {super.key});

  final StoreEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MatchingDialog.show(
        context,
        storeEntry: entry,
        onMatch: (storeEntry, gameEntry) {
          context.read<UserLibraryModel>().matchEntry(storeEntry, gameEntry);
          context
              .pushNamed('details', pathParameters: {'gid': '${gameEntry.id}'});
        },
      ),
      onSecondaryTap: () {},
      child: GridTile(
        footer: InfoTileBar(
          entry.title,
          stores: [entry.storefront],
        ),
        child: const CardCover(),
      ),
    );
  }
}
