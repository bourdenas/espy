import 'package:espy/modules/api/auth_user_api.dart';
import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/widgets/cards/cover.dart';
import 'package:espy/widgets/cards/footers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UnknownCard extends StatelessWidget {
  const UnknownCard(this.entry, {super.key});

  final StoreEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MatchingDialog.show(
        context,
        storeEntry: entry,
        onMatch: (storeEntry, digest) {
          AuthUserApi.matchEntry(storeEntry, digest.id);
          context.pushNamed('details', pathParameters: {'gid': '${digest.id}'});
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
